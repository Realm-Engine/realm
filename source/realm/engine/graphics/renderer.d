module realm.engine.graphics.renderer;
import realm.engine.graphics.batch;
import realm.engine.graphics.graphicssubsystem;
import realm.engine.graphics.core;
import realm.engine.graphics.renderpass;
import realm.engine.core;
import realm.engine.app;
import realm.engine.asset;
import realm.engine.graphics.material;
import gl3n.linalg;
import std.container.array;
import std.variant;
import std.range;
import std.typecons;
import std.meta;
import std.algorithm;
import realm.engine.debugdraw;
import realm.engine.ui.realmui;
import gl3n.frustum;
import realm.engine.container.stack;
import realm.engine.memory;
import core.stdc.stdlib;
alias LightSpaceMaterialLayout = Alias!(["cameraFar" : UserDataVarTypes.FLOAT, "cameraNear" : UserDataVarTypes.FLOAT]);
alias LightSpaceMaterial = Alias!(Material!(LightSpaceMaterialLayout));
alias ScreenPassMaterialLayout = Alias!(["screenColor" : UserDataVarTypes.VECTOR, "gamma":UserDataVarTypes.FLOAT]);
alias ScreenPassMaterial = Alias!(Material!(ScreenPassMaterialLayout));

class Renderer
{

	struct RendererMetrics
	{
		double frameTime;
	}


	private static Mesh screenMesh;

	import std.container.array;
	import std.stdio;
	private RealmVertex[][ulong] staticMeshes;
	private Batch!(RealmVertex)[ulong] batches;
	private Batch!(RealmVertex) screenBatch;
	
	private RealmGlobalData _globalData;
	private Camera* camera;
	private Camera screenCamera;
	private StandardShaderModel lightSpaceShaderProgram;
	private StandardShaderModel depthPrepassProgram;
	private StandardShaderModel screenPassProgram;
	
	private LightSpaceMaterial lightSpaceMaterial;
	private ScreenPassMaterial screenPassMaterial; 
	private DirectionalLight mainDirLight;
	private Camera lightSpaceCamera;
	private static mat4 shadowBias = mat4(vec4(0.5,0,0,0),vec4(0,0.5,0,0),vec4(0,0,0.5,0),vec4(0.5,0.5,0.5,1.0));
	private RendererMetrics metrics;
	private static bool _instantiated;
	private __gshared Renderer _instance;
	private QueryObject!() queryDevice;
	private ShaderPipeline lightSpacePipeline;
	private ShaderPipeline depthPrepassPipeline;
	alias GeometryPassInputs = Alias!(["shadowMap" : ImageFormat.DEPTH]);
	alias GeometryPassOutputs = Alias!(["cameraDepthTexture" : ImageFormat.DEPTH,"cameraScreenTexture" : ImageFormat.RGB8]);
	alias LightPassOutputs = Alias!(["shadowMap" : ImageFormat.DEPTH]);
	alias DepthPrepassOutputs = Alias!(["cameraDepthTexture" : ImageFormat.DEPTH] );
	alias ScreenPassInputs = Alias!(["cameraScreenTexture" : ImageFormat.RGB8]);
	
	//private static FrameBuffer mainFramebuffer;
	
	Renderpass!(null, null) depthPrepass;
	Renderpass!(null,LightPassOutputs) lightPass;
	Renderpass!(GeometryPassInputs,GeometryPassOutputs) geometryPass;
	Renderpass!(ScreenPassInputs,null) screenPass;
	

	static Renderer get()
	{
		if(!_instantiated)
		{
			synchronized(Renderer.classinfo)
			{
				if(!_instance)
				{
					_instance = new Renderer;
				}
				_instantiated = true;
			}
		}
		return _instance;
	}

	static void init()
	in(!_instantiated,"Renderer has already been instantiated")
	{
		synchronized(Renderer.classinfo)
		{
			if(!_instance)
			{
				_instance = new Renderer;
			}
			_instantiated = true;
		}
	}

	@property activeCamera(Camera* cam)
	{
		camera = cam;
                
	}

	@property Camera* activeCamera()
	{
		return camera;
	}

	@property RealmGlobalData* globalData()
	{
		return &_globalData;
	}

	RendererMetrics getMetrics()
	{
		return metrics;
	}
	


	this()
	{
		
		GraphicsSubsystem.initialze();
		GraphicsSubsystem.setClearColor(126,32,32,true);
		GraphicsSubsystem.enableDepthTest();
		Tuple!(int,int) windowSize = RealmApp.getWindowSize();
		_globalData.viewMatrix = _globalData.projectionMatrix = mat4.identity.value_ptr[0..16].dup;
		GraphicsSubsystem.updateGlobalData(&_globalData);
		initRenderpasses();
		enable(State.Blend);
		blendFunc(BlendFuncType.SRC_ALPHA,BlendFuncType.ONE_MINUS_SRC_ALPHA);
		lightSpaceCamera = new Camera(CameraProjection.ORTHOGRAPHIC,vec2(20,20),-20,20,0);
		screenCamera = new Camera(CameraProjection.ORTHOGRAPHIC,vec2(windowSize[0],windowSize[1]),-1,100,0);
		screenCamera.projBounds = ProjectionWindowBounds.ZERO_TO_ONE;
		
		Debug.initialze();
		RealmUI.initialize();
		queryDevice.create();
		lightSpaceShaderProgram = loadShaderProgram("$EngineAssets/Shaders/lightSpace.shader","lightSpace");
		depthPrepassProgram = loadShaderProgram("$EngineAssets/Shaders/depthPrepass.shader","Depth prepass");
		screenPassProgram = loadShaderProgram("$EngineAssets/Shaders/screenPass.shader","Screen pass");
		lightSpacePipeline = new ShaderPipeline;
		lightSpacePipeline.create();
		lightSpacePipeline.useProgramStages(lightSpaceShaderProgram);
		depthPrepassPipeline = new ShaderPipeline;
		depthPrepassPipeline.create();
		depthPrepassPipeline.useProgramStages(depthPrepassProgram);


		screenMesh = loadMesh("$EngineAssets/Models/screen_quad.obj");
		ScreenPassMaterial.initialze();
		ScreenPassMaterial.reserve(1);
		screenPassMaterial = new ScreenPassMaterial;
		screenPassMaterial.gamma = 2.2f;
		screenPassMaterial.screenColor = vec4(1.0);
		ScreenPassMaterial.allocate(&screenMesh);
		screenBatch = new Batch!RealmVertex(MeshTopology.TRIANGLE, screenPassProgram,ScreenPassMaterial.getOrder());
		screenBatch.setShaderStorageCallback(&(ScreenPassMaterial.bindShaderStorage));
		screenBatch.setPrepareDrawCallback(&prepareScreenPass);
		screenBatch.initialize(ScreenPassMaterial.allocatedVertices(),ScreenPassMaterial.allocatedElements());
		screenBatch.reserve(ScreenPassMaterial.getNumMaterialInstances());
		
	
	}



	void initRenderpasses()
	{
		Tuple!(int,int) windowSize = RealmApp.getWindowSize();
		screenPass = new Renderpass!(ScreenPassInputs,null)(windowSize[0],windowSize[1]);
		depthPrepass = new Renderpass!(null,null)(windowSize[0],windowSize[1]);
		lightPass = new Renderpass!(null,LightPassOutputs)(2048,2048);
		geometryPass = new Renderpass!(GeometryPassInputs,GeometryPassOutputs)(windowSize[0],windowSize[1]);
		geometryPass.inputs.shadowMap = lightPass.getOutputs().shadowMap;
		screenPass.inputs.cameraScreenTexture = geometryPass.getOutputs().cameraScreenTexture;
		//geometryPass.inputs.cameraDepthTexture = depthPrepass.getOutputs().cameraDepthTexture;
		//mainFramebuffer.create!(true)(windowSize[0],windowSize[1],[FrameBufferAttachmentType.COLOR_ATTACHMENT,  FrameBufferAttachmentType.DEPTH_ATTACHMENT]);
		
	}


	void submitMesh(Mat, bool isStatic = false)(Mesh* mesh,Transform transform,Mat mat,ref RealmVertex[] vertexData)
	{
		ulong materialId = Mat.materialId();
		ulong staticId = materialId + mat.instanceId;
		if(!isStatic || (isStatic && staticId !in staticMeshes))
		{
			//vertexData.length = mesh.positions.length;
			mat4 modelMatrix = transform.transformation;
			mat4 transInv = modelMatrix.inverse().transposed();

			for(int i = 0; i < mesh.positions.length;i++)
			{
				RealmVertex vertex;

				vertex.position = vec3( modelMatrix * vec4(mesh.positions[i],1.0));

				vertex.texCoord = mesh.textureCoordinates[i];
				vertex.normal =  vec3(transInv * vec4(mesh.normals[i],1.0));
				vertex.tangent = vec3(modelMatrix * vec4(mesh.tangents[i],1.0));
				vertex.materialId = mat.instanceId;
				vertexData[i] = vertex;

			}
		}



		AABB boundingBox = aabbTransformWorldSpace(mesh.getLocalBounds(),transform.transformation);
		mat4 vp  = camera.projection * camera.view;
		Frustum frustum = Frustum(vp );

		int intersection = frustum.intersects(boundingBox);

		static if(isStatic)
		{

			if(staticId !in staticMeshes)
			{
				staticMeshes[staticId] = vertexData;
			}
		}

		if(intersection == INSIDE || intersection == INTERSECT)
		{

			if(materialId !in batches)
			{

				batches[materialId] = new Batch!(RealmVertex)(MeshTopology.TRIANGLE,Mat.getShaderProgram(),Mat.getOrder());
				Batch!(RealmVertex) batch = batches[materialId];
				batch.setShaderStorageCallback(&(Mat.bindShaderStorage));

				batch.initialize(Mat.allocatedVertices(),Mat.allocatedElements());
				batch.reserve(Mat.getNumMaterialInstances());
			}
			auto batch = materialId in batches;
			batch.submitVertices!(Mat)(vertexData,mesh.faces,mat,transform.transformation);
			Debug.drawBox(boundingBox.center(), boundingBox.extent(),vec3(0),vec3(0,1,0));
		}

		else
		{
			Debug.drawBox(boundingBox.center(), boundingBox.extent(),vec3(0),vec3(1,0,0));
		}
	}

	void submitMesh(Mat, bool isStatic = false)(Mesh* mesh,Transform transform,Mat mat)
	{
		import core.stdc.stdlib;

		static assert(isMaterial!(Mat));
		ulong materialId = Mat.materialId();


		RealmVertex[] vertexData;
		
		ulong staticId = materialId + mat.instanceId;
		static if(isStatic)
		{

			if(staticId in staticMeshes)
			{
				vertexData = staticMeshes[staticId];
				
			}
		}
		
		if(!isStatic || (isStatic && staticId !in staticMeshes))
		{

			vertexData = RealmHeapAllocator!(RealmVertex).allocate(mesh.positions.length);
			submitMesh!(Mat,isStatic)(mesh,transform,mat,vertexData);
			scope(exit)
			{
				 RealmHeapAllocator!(RealmVertex).deallocate(vertexData.ptr);
			}
			
		}
		submitMesh!(Mat,isStatic)(mesh,transform,mat,vertexData);
		



		


	}

	void renderLightSpace() 
	{
	
		if(mainDirLight !is null)
		{
			lightPass.startPass();

			cull(CullFace.FRONT);
			//lightSpaceCamera.update();

			mat4 view = mat4.look_at(-mainDirLight.getComponent!(Transform).front,vec3(0,0,0),vec3(0,1,0));
			mat4 lightSpaceMatrix = lightSpaceCamera.projection * view;
			lightSpaceMatrix.transpose();
			float[16] lightSpaceDup = lightSpaceMatrix.value_ptr[0..16].dup;
			_globalData.viewMatrix[0..$] = lightSpaceCamera.view.transposed.value_ptr[0..16].dup;
			_globalData.projectionMatrix[0..$] = lightSpaceCamera.projection.transposed.value_ptr[0..16].dup;
			//_globalData.vp[0..$] = lightSpaceDup;
			_globalData.lightSpaceMatrix[0..$] =  lightSpaceDup;
			GraphicsSubsystem.updateGlobalData(&_globalData);


			auto orderedBatches = batches.values.sort!((b1, b2) => b1.renderOrder < b2.renderOrder);

			foreach(batch; orderedBatches)
			{
				batch.setPrepareDrawCallback(&prepareDrawLightpass);
				batch.drawBatch!(false)(lightSpacePipeline);

			}

			
			
			//cull(CullFace.BACK);
		}
		
	}

	@property void mainLight(DirectionalLight light)
	{
		mainDirLight = light;
		
	}

	void updateMainLight()
	{
		//mainDirLight = light;
		Transform lightTransform = mainDirLight.getComponent!(Transform);
		vec4 direction = vec4(lightTransform.front.normalized(),1.0);
		_globalData.mainLightDirection[0..$] = direction.value_ptr[0..4].dup;
		_globalData.mainLightColor[0..$] = vec4(mainDirLight.color,0.0).value_ptr[0..4].dup;
		

	}

	void renderDepthPrepass()
	{
		depthPrepass.startPass();
		auto orderedBatches = batches.values.sort!((b1, b2) => b1.renderOrder < b2.renderOrder);

		foreach(batch; orderedBatches)
		{
			batch.setPrepareDrawCallback(&prepareDrawLightpass);
			batch.drawBatch!(false)(depthPrepassPipeline);

		}
	}

	void update()
	{
		if(mainDirLight !is null)
		{
			updateMainLight();
		}

		renderLightSpace();
		if(camera !is null)
		{
			//mat4 vp = camera.projection * camera.view;
			//vp.transpose();
			_globalData.viewMatrix[0..$] = camera.view.transposed.value_ptr[0..16].dup;
			_globalData.projectionMatrix[0..$] = camera.projection.transposed.value_ptr[0..16].dup;
			//_globalData.vp[0..$] = vp.value_ptr[0..16].dup;
			_globalData.camPosition[0..$] = camera.transform.position.value_ptr[0..4].dup;
			_globalData.camDirection[0..$] = camera.transform.front.value_ptr[0..4].dup;
			_globalData.nearPlane = camera.nearPlane;
			_globalData.farPlane = camera.farPlane;
			_globalData.size[0..$] = camera.size.value_ptr[0..2].dup;
		}
		GraphicsSubsystem.updateGlobalData(&_globalData);
		//renderDepthPrepass();
		

		
		setViewport(0,0,geometryPass.getFramebuffer().width,geometryPass.getFramebuffer().height);
		auto orderedBatches = batches.values.sort!((b1, b2) => b1.renderOrder < b2.renderOrder);
		geometryPass.getFramebuffer().bind(FrameBufferTarget.DRAW);

		drawBuffers([DrawBufferTarget.COLOR]);
		GraphicsSubsystem.clearScreen();
		
		

		

		foreach(batch; orderedBatches)
		{
			batch.setPrepareDrawCallback(&prepareDrawGeometry);
			batch.drawBatch!(true)();
		}
		Debug.flush();
		RealmUI.flush();
		geometryPass.getFramebuffer().unbind(FrameBufferTarget.DRAW );
		drawToScreen();
		//geometryPass.getFramebuffer().blitToScreen(FrameMask.COLOR );
		foreach(batch; orderedBatches)
		{
			batch.resetBatch();
		}

		long timeElapsed = 0;
		
		
		
	}

	void drawToScreen()
	{
		
		Tuple!(int,int) windowSize = RealmApp.getWindowSize();
		Transform transform = new Transform(vec3(0),vec3(0),vec3(windowSize[0],windowSize[1],1));
		transform.updateTransformation();
		GraphicsSubsystem.clearScreen();
		screenCamera.update();
		globalData.projectionMatrix[0..$] = screenCamera.projection.transposed.value_ptr[0..16].dup;
		globalData.viewMatrix[0..$] = mat4.identity.transposed.value_ptr[0..16];
		GraphicsSubsystem.updateGlobalData(Renderer.get.globalData);
		RealmVertex[] vertices = (cast(RealmVertex*)alloca(RealmVertex.sizeof * screenMesh.positions.length))[0.. screenMesh.positions.length];
		for(int i = 0; i < screenMesh.positions.length;i++)
		{
			RealmVertex vertex;
			vertex.position = vec3(transform.transformation * vec4(screenMesh.positions[i],1.0));
			vertex.texCoord = screenMesh.textureCoordinates[i];
			vertex.normal = vec3(0,0,1);
			vertex.tangent = screenMesh.tangents[i];
			vertex.materialId = screenPassMaterial.instanceId;
			vertices[i] = vertex;
		}
		screenBatch.submitVertices(vertices,screenMesh.faces,screenPassMaterial);
		screenBatch.drawBatch!(false)();
		screenBatch.resetBatch();
	}

	ref ScreenPassMaterial getScreenPassMaterial()
	{
		return screenPassMaterial;
	}

	void prepareDrawGeometry(StandardShaderModel program)
	{
		geometryPass.bindAttachments(program);

		
		


	}

	void prepareDrawLightpass(StandardShaderModel program)
	{
		lightPass.bindAttachments(program);
	}

	void prepareDrawDepthprepass(StandardShaderModel program)
	{
		depthPrepass.bindAttachments(program);
	}

	void prepareScreenPass(StandardShaderModel program)
	{
		screenPass.bindAttachments(program);
	}
	
	

	void flush()
	{
		
	}


	

}
