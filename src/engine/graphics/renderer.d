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
alias ScreenMaterialLayout = Alias!(["screenTexture" : UserDataVarTypes.SCREENTEXTURE]);
alias ScreenMaterial = Alias!(Material!(ScreenMaterialLayout));
alias LightSpaceMaterialLayout = Alias!(["cameraFar" : UserDataVarTypes.FLOAT, "cameraNear" : UserDataVarTypes.FLOAT]);
alias LightSpaceMaterial = Alias!(Material!(LightSpaceMaterialLayout));

class Renderer
{
	import std.container.array;
	import std.stdio;
	//private Batch!RealmVertex batch;
	
	private Batch!(RealmVertex)[ulong] batches;
	private Batch!(RealmVertex) lightSpaceBatch;
	VertexAttribute[] vertex3DAttributes;
	private RealmGlobalData globalData;
	private Camera* camera;
	private static FrameBuffer mainFrameBuffer;
	private ShaderProgram lightSpaceShaderProgram;
	private LightSpaceMaterial lightSpaceMaterial;
	private DirectionalLight* mainDirLight;
	private Camera lightSpaceCamera;
	private static mat4 shadowBias = mat4(vec4(0.5,0,0,0),vec4(0,0.5,0,0),vec4(0,0,0.5,0),vec4(0.5,0.5,0.5,1.0));
	@property activeCamera(Camera* cam)
	{
		camera = cam;
		lightSpaceMaterial.cameraFar = cam.farPlane;
		lightSpaceMaterial.cameraNear = cam.nearPlane;
                
	}


	this()
	{
		
		GraphicsSubsystem.initialze();
		GraphicsSubsystem.setClearColor(126,32,32,true);
		GraphicsSubsystem.enableDepthTest();
		globalData.vp = mat4.identity.value_ptr[0..16].dup;
                
		GraphicsSubsystem.updateGlobalData(&globalData);
		VertexAttribute position = {VertexType.FLOAT3,0,0};
		VertexAttribute texCoord = {VertexType.FLOAT2,12,1};
		VertexAttribute normal = {VertexType.FLOAT3,20,2};
		VertexAttribute tangent = {VertexType.FLOAT3,32,3};
		vertex3DAttributes ~= position;
		vertex3DAttributes ~= texCoord;
		vertex3DAttributes ~= normal;
		vertex3DAttributes ~= tangent;
		Tuple!(int,int) windowSize = RealmApp.getWindowSize();
		mainFrameBuffer.create!([FrameBufferAttachmentType.COLOR_ATTACHMENT,  FrameBufferAttachmentType.DEPTH_ATTACHMENT])(windowSize[0],windowSize[1]);
		LightSpaceMaterial.initialze();
		LightSpaceMaterial.reserve(2);
		lightSpaceMaterial = new LightSpaceMaterial;

		lightSpaceShaderProgram = loadShaderProgram("./src/engine/Assets/Shaders/simpleShaded.shader","Simple shaded");
		lightSpaceMaterial.setShaderProgram(lightSpaceShaderProgram);
		lightSpaceMaterial.recieveShadows = false;
		enable(State.Blend);
		blendFunc(BlendFuncType.SRC_ALPHA,BlendFuncType.ONE_MINUS_SRC_ALPHA);
		
		lightSpaceCamera = new Camera(CameraProjection.ORTHOGRAPHIC,vec2(5,5),-10,20,0);
		lightSpaceBatch = new Batch!(RealmVertex)(MeshTopology.TRIANGLE,lightSpaceShaderProgram,0);
		lightSpaceBatch.initialize(vertex3DAttributes, 4096);
		lightSpaceBatch.reserve(4);
		lightSpaceBatch.setShaderStorageCallback(&(LightSpaceMaterial.bindShaderStorage));

	}
	static FrameBuffer* getMainFrameBuffer()
	{
		assert (&mainFrameBuffer !is null);
		return &mainFrameBuffer;
	}

	void submitMesh(Mat)(Mesh mesh,Transform transform,Mat mat)
	{
		static assert(isMaterial!(Mat));
		
		RealmVertex[] vertexData;
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
			vertexData[i] = vertex;
		}
		ulong materialId = Mat.materialId();
		if(auto batch = materialId in batches)
		{
			batch.submitVertices!(Mat)(vertexData,mesh.faces,mat);
		}
		else
		{

			batches[materialId] = new Batch!(RealmVertex)(MeshTopology.TRIANGLE,Mat.getShaderProgram(),Mat.getOrder());
			batches[materialId].setShaderStorageCallback(&(Mat.bindShaderStorage));
			batches[materialId].initialize(vertex3DAttributes,2048);
			batches[materialId].reserve(4);
			batches[materialId].submitVertices!(Mat)(vertexData,mesh.faces,mat);
		}
		//lightSpaceBatch.submitVertices!(LightSpaceMaterial)(vertexData,mesh.faces,lightSpaceMaterial);
		
		
		
		
	}

	void renderLightSpace()
	{
	
		cull(CullFace.FRONT);
		lightSpaceCamera.yaw = mainDirLight.transform.rotation.y;
		lightSpaceCamera.pitch = mainDirLight.transform.rotation.x;
		
		//lightSpaceCamera.update();
		
		mat4 view = mat4.look_at(lightSpaceCamera.front,vec3(0,0,0),vec3(0,1,0));
		mat4 lightSpaceMatrix = lightSpaceCamera.projection * view;
		lightSpaceMatrix.transpose();
		globalData.vp[0..$] = lightSpaceMatrix.value_ptr[0..16].dup;
		globalData.lightSpaceMatrix[0..$] =  lightSpaceMatrix.value_ptr[0..16].dup;
		GraphicsSubsystem.updateGlobalData(&globalData);
		mainDirLight.shadowFrameBuffer.refresh();
		mainDirLight.shadowFrameBuffer.bind(FrameBufferTarget.FRAMEBUFFER);
		GraphicsSubsystem.clearScreen();
		
		auto orderedBatches = batches.values.sort!((b1, b2) => b1.renderOrder < b2.renderOrder);
		foreach(batch; orderedBatches)
		{
			batch.drawBatch!(false)();
		}
		mainDirLight.shadowFrameBuffer.unbind(FrameBufferTarget.FRAMEBUFFER);
		//mainDirLight.shadowFrameBuffer.blitToScreen(FrameMask.COLOR );
		GraphicsSubsystem.setShadowMap(mainDirLight.shadowFrameBuffer.fbAttachments[FrameBufferAttachmentType.DEPTH_ATTACHMENT].texture);
		cull(CullFace.BACK);
	}

	@property void mainLight(DirectionalLight* light)
	{
		mainDirLight = light;
		mainDirLight.createFrameBuffer();
	}

	void updateMainLight()
	{
		//mainDirLight = light;
		mainDirLight.transform.updateTransformation();
		mat4 modelMatrix = mainDirLight.transform.transformation;
		vec4 direction = vec4(mainDirLight.transform.front,1.0);
		globalData.mainLightDirection[0..$] = direction.value_ptr[0..4].dup;
		globalData.mainLightColor[0..$] = vec4(mainDirLight.color,0.0).value_ptr[0..4].dup;
		

	}

	void update()
	{
		if(mainDirLight !is null)
		{
			updateMainLight();
		}
		renderLightSpace();
		auto orderedBatches = batches.values.sort!((b1, b2) => b1.renderOrder < b2.renderOrder);
		mainFrameBuffer.refresh();
		mainFrameBuffer.bind(FrameBufferTarget.DRAW);
		drawBuffers([DrawBufferTarget.COLOR]);
		GraphicsSubsystem.clearScreen();
		if(camera !is null)
		{
			//camera.updateViewProjection();
			mat4 vp = camera.projection * camera.view;
			vp.transpose();
			globalData.vp[0..$] = vp.value_ptr[0..16].dup;
		}

		GraphicsSubsystem.updateGlobalData(&globalData);
		
		foreach(batch; orderedBatches)
		{
			batch.drawBatch!(true)();
		}
		
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
