module realm.engine.graphics.renderer;
import realm.engine.graphics.batch;
import realm.engine.graphics.graphicssubsystem;
import realm.engine.graphics.core;
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
alias LightSpaceMaterialLayout = Alias!(["cameraFar" : UserDataVarTypes.FLOAT, "cameraNear" : UserDataVarTypes.FLOAT]);
alias LightSpaceMaterial = Alias!(Material!(LightSpaceMaterialLayout));

class Renderer
{

	struct RenderInfo
	{
		ulong lastRenderTimeStamp;
		ulong currentFrameRenderTime;
	}

	import std.container.array;
	import std.stdio;
	//private Batch!RealmVertex batch;
	private RealmVertex[][ulong] staticMeshes;
	private Batch!(RealmVertex)[ulong] batches;
	private Batch!(RealmVertex) lightSpaceBatch;
	private RealmGlobalData _globalData;
	private Camera* camera;
	private static FrameBuffer mainFrameBuffer;
	private StandardShaderModel lightSpaceShaderProgram;
	private LightSpaceMaterial lightSpaceMaterial;
	private DirectionalLight mainDirLight;
	private Camera lightSpaceCamera;
	private static mat4 shadowBias = mat4(vec4(0.5,0,0,0),vec4(0,0.5,0,0),vec4(0,0,0.5,0),vec4(0.5,0.5,0.5,1.0));
	
	private static bool _instantiated;
	private __gshared Renderer _instance;
	private QueryObject!() queryDevice;
	private RenderInfo _info;
	private ShaderPipeline lightSpacePipeline;

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
	


	this()
	{
		
		GraphicsSubsystem.initialze();
		GraphicsSubsystem.setClearColor(126,32,32,true);
		GraphicsSubsystem.enableDepthTest();
		_globalData.vp = mat4.identity.value_ptr[0..16].dup;
                
		GraphicsSubsystem.updateGlobalData(&_globalData);
		Tuple!(int,int) windowSize = RealmApp.getWindowSize();
		mainFrameBuffer.create!([FrameBufferAttachmentType.COLOR_ATTACHMENT,  FrameBufferAttachmentType.DEPTH_ATTACHMENT])(windowSize[0],windowSize[1]);
		
		enable(State.Blend);
		blendFunc(BlendFuncType.SRC_ALPHA,BlendFuncType.ONE_MINUS_SRC_ALPHA);
		
		lightSpaceCamera = new Camera(CameraProjection.ORTHOGRAPHIC,vec2(20,20),-20,20,0);
		Debug.initialze();

		RealmUI.initialize();
		queryDevice.create();
		lightSpaceShaderProgram = loadShaderProgram("$EngineAssets/Shaders/lightSpace.shader","lightSpace");
		lightSpacePipeline = new ShaderPipeline;
		lightSpacePipeline.create();
		lightSpacePipeline.useProgramStages(lightSpaceShaderProgram);
		enable(State.FrameBufferSRGB);
		


	}
	static FrameBuffer* getMainFrameBuffer()
	{
		assert (&mainFrameBuffer !is null);
		return &mainFrameBuffer;
	}

	void submitMesh(Mat, bool isStatic = false)(Mesh mesh,Transform transform,Mat mat)
	{
		

		static assert(isMaterial!(Mat));
		ulong materialId = Mat.materialId();


		RealmVertex[] vertexData;
		vec3[] aabbPoints;
		ulong staticId = materialId + mat.instanceId;
		static if(isStatic)
		{

			if(staticId in staticMeshes)
			{
				vertexData = staticMeshes[staticId];
				foreach(vertex; vertexData)
				{
					aabbPoints ~= vertex.position;
				}
			}
		}

		if(!isStatic || (isStatic && staticId !in staticMeshes))
		{
			vertexData.length = mesh.positions.length;
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
				aabbPoints ~= vertex.position;
				vertexData[i] = vertex;

			}
		}
		
		
		
		AABB boundingBox = AABB.from_points(aabbPoints);
		Frustum frustum = Frustum((camera.projection * camera.view) );
		
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
				batches[materialId].setShaderStorageCallback(&(Mat.bindShaderStorage));
				batches[materialId].initialize(Mat.allocatedVertices(),Mat.allocatedElements());
				batches[materialId].reserve(Mat.getNumMaterialInstances());
			}
			auto batch = materialId in batches;
			batch.submitVertices!(Mat)(vertexData,mesh.faces,mat);
			Debug.drawBox(boundingBox.center(), boundingBox.extent(),vec3(0),vec3(0,1,0));
		}

		else
		{
			Debug.drawBox(boundingBox.center(), boundingBox.extent(),vec3(0),vec3(1,0,0));
		}


	}

	void renderLightSpace() 
	{
	
		if(mainDirLight !is null)
		{
			FrameBuffer* shadowFramebuffer = &mainDirLight.shadowFrameBuffer;
			setViewport(0,0,shadowFramebuffer.width, shadowFramebuffer.height);
			mainDirLight.shadowFrameBuffer.bind(FrameBufferTarget.FRAMEBUFFER);

			//mainDirLight.shadowFrameBuffer.refresh();
			GraphicsSubsystem.clearScreen();

			cull(CullFace.FRONT);
			//lightSpaceCamera.update();

			mat4 view = mat4.look_at(-mainDirLight.getComponent!(Transform).front,vec3(0,0,0),vec3(0,1,0));
			mat4 lightSpaceMatrix = lightSpaceCamera.projection * view;
			lightSpaceMatrix.transpose();
			float[16] lightSpaceDup = lightSpaceMatrix.value_ptr[0..16].dup;
			_globalData.vp[0..$] = lightSpaceDup;
			_globalData.lightSpaceMatrix[0..$] =  lightSpaceDup;
			GraphicsSubsystem.updateGlobalData(&_globalData);


			auto orderedBatches = batches.values.sort!((b1, b2) => b1.renderOrder < b2.renderOrder);

			foreach(batch; orderedBatches)
			{
				batch.drawBatch!(false)(lightSpacePipeline);
			}

			mainDirLight.shadowFrameBuffer.unbind(FrameBufferTarget.FRAMEBUFFER);
			GraphicsSubsystem.setShadowMap(mainDirLight.shadowFrameBuffer.fbAttachments[FrameBufferAttachmentType.DEPTH_ATTACHMENT].texture);
			//cull(CullFace.BACK);
		}
		
	}

	@property void mainLight(DirectionalLight light)
	{
		mainDirLight = light;
		mainDirLight.createFrameBuffer(2048,2048);
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

	private void updateGlobalData()
	{
		
	}



	void update()
	{
		if(mainDirLight !is null)
		{
			updateMainLight();
		}

		renderLightSpace();
		

		setViewport(0,0,mainFrameBuffer.width,mainFrameBuffer.height);
		auto orderedBatches = batches.values.sort!((b1, b2) => b1.renderOrder < b2.renderOrder);
		mainFrameBuffer.bind(FrameBufferTarget.DRAW);
		
		drawBuffers([DrawBufferTarget.COLOR]);
		GraphicsSubsystem.clearScreen();
		if(camera !is null)
		{
			mat4 vp = camera.projection * camera.view;
			vp.transpose();
			_globalData.vp[0..$] = vp.value_ptr[0..16].dup;
			_globalData.camPosition[0..$] = camera.transform.position.value_ptr[0..4].dup;
			_globalData.camDirection[0..$] = camera.transform.front.value_ptr[0..4].dup;
			_globalData.nearPlane = camera.nearPlane;
			_globalData.farPlane = camera.farPlane;
			_globalData.size[0..$] = camera.size.value_ptr[0..2].dup;
		}

		GraphicsSubsystem.updateGlobalData(&_globalData);
		
		foreach(batch; orderedBatches)
		{
			batch.drawBatch!(true)();
		}
		Debug.flush();
		RealmUI.flush();
		mainFrameBuffer.unbind(FrameBufferTarget.DRAW );
		mainFrameBuffer.blitToScreen(FrameMask.COLOR );

		foreach(batch; orderedBatches)
		{
			batch.resetBatch();
		}
		
	}
	

	void flush()
	{
		
	}


	

}
