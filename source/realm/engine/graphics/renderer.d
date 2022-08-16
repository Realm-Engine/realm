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
alias LightSpaceMaterialLayout = Alias!(["cameraFar" : UserDataVarTypes.FLOAT, "cameraNear" : UserDataVarTypes.FLOAT]);
alias LightSpaceMaterial = Alias!(Material!(LightSpaceMaterialLayout));

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
	private Batch!(RealmVertex) lightSpaceBatch;
	private RealmGlobalData _globalData;
	private Camera* camera;
	private StandardShaderModel lightSpaceShaderProgram;
	private StandardShaderModel depthPrepassProgram;
	private LightSpaceMaterial lightSpaceMaterial;
	 
	private DirectionalLight mainDirLight;
	private Camera lightSpaceCamera;
	private static mat4 shadowBias = mat4(vec4(0.5,0,0,0),vec4(0,0.5,0,0),vec4(0,0,0.5,0),vec4(0.5,0.5,0.5,1.0));
	private RendererMetrics metrics;
	private static bool _instantiated;
	private __gshared Renderer _instance;
	private QueryObject!() queryDevice;
	private ShaderPipeline lightSpacePipeline;
	private ShaderPipeline depthPrepassPipeline;
	alias GeometryPassInputs = Alias!(["shadowMap" : ImageFormat.DEPTH,"cameraDepthTexture" : ImageFormat.DEPTH]);
	alias GeometryPassOutputs = Alias!(["cameraScreenTexture" : ImageFormat.RGB8]);
	alias LightPassOutputs = Alias!(["shadowMap" : ImageFormat.DEPTH]);
	alias DepthPrepassOutputs = Alias!(["cameraDepthTexture" : ImageFormat.DEPTH] );
	private static FrameBuffer mainFramebuffer;
	
	Renderpass!(null, DepthPrepassOutputs) depthPrepass;
	Renderpass!(null,LightPassOutputs) lightPass;
	Renderpass!(GeometryPassInputs,GeometryPassOutputs) geometryPass;
	
	

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
		_globalData.viewMatrix = _globalData.projectionMatrix = mat4.identity.value_ptr[0..16].dup;
                
		GraphicsSubsystem.updateGlobalData(&_globalData);
		initRenderpasses();
		enable(State.Blend);
		blendFunc(BlendFuncType.SRC_ALPHA,BlendFuncType.ONE_MINUS_SRC_ALPHA);
		
		lightSpaceCamera = new Camera(CameraProjection.ORTHOGRAPHIC,vec2(20,20),-20,20,0);
		Debug.initialze();

		RealmUI.initialize();
		queryDevice.create();
		lightSpaceShaderProgram = loadShaderProgram("$EngineAssets/Shaders/lightSpace.shader","lightSpace");
		depthPrepassProgram = loadShaderProgram("$EngineAssets/Shaders/depthPrepass.shader","Depth prepass");
		lightSpacePipeline = new ShaderPipeline;
		lightSpacePipeline.create();
		lightSpacePipeline.useProgramStages(lightSpaceShaderProgram);
		depthPrepassPipeline = new ShaderPipeline;
		depthPrepassPipeline.create();
		depthPrepassPipeline.useProgramStages(depthPrepassProgram);
		enable(State.FrameBufferSRGB);

		screenMesh = loadMesh("$EngineAssets/Models/screen_quad.obj");

	
	}

	void initRenderpasses()
	{
		Tuple!(int,int) windowSize = RealmApp.getWindowSize();
		depthPrepass = new Renderpass!(null,DepthPrepassOutputs)(windowSize[0],windowSize[1]);
		lightPass = new Renderpass!(null,LightPassOutputs)(2048,2048);
		geometryPass = new Renderpass!(GeometryPassInputs,GeometryPassOutputs)(windowSize[0],windowSize[1]);
		geometryPass.inputs.shadowMap = lightPass.getOutputs().shadowMap;
		geometryPass.inputs.cameraDepthTexture = depthPrepass.getOutputs().cameraDepthTexture;
		mainFramebuffer.create!(true)(windowSize[0],windowSize[1],[FrameBufferAttachmentType.COLOR_ATTACHMENT,  FrameBufferAttachmentType.DEPTH_ATTACHMENT]);
		
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
		//lightTransform.updateTransformation();
		//mat4 modelMatrix = mainDirLight.transform.transformation;
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
		renderDepthPrepass();
		


		setViewport(0,0,mainFramebuffer.width,mainFramebuffer.height);
		auto orderedBatches = batches.values.sort!((b1, b2) => b1.renderOrder < b2.renderOrder);
		mainFramebuffer.bind(FrameBufferTarget.DRAW);

		drawBuffers([DrawBufferTarget.COLOR]);
		GraphicsSubsystem.clearScreen();
		
		

		

		foreach(batch; orderedBatches)
		{
			batch.setPrepareDrawCallback(&prepareDrawGeometry);
			batch.drawBatch!(true)();
		}
		Debug.flush();
		RealmUI.flush();
		mainFramebuffer.unbind(FrameBufferTarget.DRAW );
		mainFramebuffer.blitToScreen(FrameMask.COLOR );
		foreach(batch; orderedBatches)
		{
			batch.resetBatch();
		}

		long timeElapsed = 0;
		
		
		
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
	
	

	void flush()
	{
		
	}


	

}
