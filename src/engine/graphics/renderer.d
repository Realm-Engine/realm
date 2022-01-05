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
		
		lightSpaceCamera = new Camera(CameraProjection.ORTHOGRAPHIC,vec2(10,10),1,7.5,0);
		lightSpaceBatch = new Batch!(RealmVertex)(MeshTopology.TRIANGLE,lightSpaceShaderProgram,0);
		lightSpaceBatch.initialize(vertex3DAttributes, 4096,4096* 3);
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
			batches[materialId].initialize(vertex3DAttributes,cast(uint)vertexData.length,cast(uint)mesh.faces.length);
			batches[materialId].reserve(2);
			batches[materialId].submitVertices!(Mat)(vertexData,mesh.faces,mat);
		}
		//lightSpaceBatch.submitVertices!(LightSpaceMaterial)(vertexData,mesh.faces,lightSpaceMaterial);
		
		
		
		
	}

	void renderLightSpace()
	{
	
		
		FrameBuffer shadowFramebuffer = mainDirLight.shadowFrameBuffer;
		setViewport(0,0,shadowFramebuffer.width, shadowFramebuffer.height);
		cull(CullFace.FRONT);
		//lightSpaceCamera.update();
		
		mat4 view = mat4.look_at(mainDirLight.transform.front,vec3(0,0,0),vec3(0,1,0));
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
		mainDirLight.createFrameBuffer(2048,2048);
	}

	void updateMainLight()
	{
		//mainDirLight = light;
		mainDirLight.transform.updateTransformation();
		//mat4 modelMatrix = mainDirLight.transform.transformation;
		vec4 direction = vec4(mainDirLight.transform.front,0.0);
		globalData.mainLightDirection[0..$] = direction.value_ptr[0..4].dup;
		globalData.mainLightColor[0..$] = vec4(mainDirLight.color,0.0).value_ptr[0..4].dup;
		

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
			globalData.camPosition[0..$] = camera.transform.position.value_ptr[0..4].dup;
			globalData.camDirection[0..$] = camera.transform.front.value_ptr[0..4].dup;
			globalData.nearPlane = camera.nearPlane;
			globalData.farPlane = camera.farPlane;
			globalData.size[0..$] = camera.size.value_ptr[0..2].dup;
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
