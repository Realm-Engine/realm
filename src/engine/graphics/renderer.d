module realm.engine.graphics.renderer;
import realm.engine.graphics.batch;
import realm.engine.graphics.graphicssubsystem;
import realm.engine.graphics.core;
import realm.engine.core;
import realm.engine.graphics.material;
import gl3n.linalg;
import std.container.array;
import std.variant;
import std.range;


class Renderer
{
	import std.container.array;
	import std.stdio;
	//private Batch!RealmVertex batch;
	
	private Batch!(RealmVertex)[ulong] batches;

	VertexAttribute[] vertex3DAttributes;
	private RealmGlobalData globalData;
	private Camera* camera;
 
  

	@property activeCamera(Camera* cam)
	{
		camera = cam;
                
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

			batches[materialId] = new Batch!(RealmVertex)(MeshTopology.TRIANGLE,Mat.getShaderProgram());
			batches[materialId].setShaderStorageCallback(&(Mat.bindShaderStorage));
			batches[materialId].initialize(vertex3DAttributes,2048);
			batches[materialId].reserve(1);
			batches[materialId].submitVertices!(Mat)(vertexData,mesh.faces,mat);
		}
		

		
		
	}

	void mainLight(DirectionalLight light)
	{
		light.transform.updateTransformation;
		mat4 modelMatrix = light.transform.transformation;
		vec4 direction = modelMatrix * vec4(vec3(0,-1,0),1.0);
		globalData.mainLightDirection[0..$] = direction.value_ptr[0..4].dup;
		globalData.mainLightColor[0..$] = vec4(light.color,0.0).value_ptr[0..4].dup;
		

	}

	void update()
	{
		GraphicsSubsystem.clearScreen();
		if(camera !is null)
		{
			//camera.updateViewProjection();
			mat4 vp = camera.projection * camera.view;
			globalData.vp[0..$] = vp.value_ptr[0..16].dup;
		}
		GraphicsSubsystem.updateGlobalData(&globalData);
		foreach(batch; batches)
		{
			batch.drawBatch();
		}


		
	}

	void flush()
	{
		
	}


	

}
