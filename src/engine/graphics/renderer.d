module realm.engine.graphics.renderer;
import realm.engine.graphics.batch;
import realm.engine.graphics.graphicssubsystem;
import realm.engine.graphics.core;
import realm.engine.core;
import realm.engine.graphics.material;
import gl3n.linalg;
import std.container.array;
import std.variant;
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
		globalData.viewProjection = mat4.identity;
		GraphicsSubsystem.updateGlobalData(&globalData);
		VertexAttribute position = {VertexType.FLOAT3,0,0};
		VertexAttribute texCoord = {VertexType.FLOAT2,12,1};
		vertex3DAttributes ~= position;
		vertex3DAttributes ~= texCoord;

	}

	void submitMesh(Mat)(Mesh mesh,Transform transform,Mat mat)
	{
		static assert(isMaterial!(Mat));
		
		RealmVertex[uint] vertexData;
		mat4 modelMatrix = transform.model;
		foreach(index; mesh.faces)
		{
			RealmVertex vertex;
			
			vertex.position = vec3(modelMatrix * vec4(mesh.positions[index],1.0));
			vertex.texCoord = mesh.textureCoordinates[index];
			vertexData[index] = vertex;
		}
		ulong materialId = Mat.materialId();
		if(auto batch = materialId in batches)
		{
			batch.submitVertices!(Mat)(vertexData.values,mesh.faces,mat);
		}
		else
		{

			batches[materialId] = new Batch!(RealmVertex)(MeshTopology.TRIANGLE);
			batches[materialId].initialize(vertex3DAttributes,64);
			batches[materialId].reserve(2);
			batches[materialId].submitVertices!(Mat)(vertexData.values,mesh.faces,mat);
		}
		

		
		
	}

	void update()
	{
		GraphicsSubsystem.clearScreen();
		if(camera !is null)
		{
			camera.updateViewProjection();
			globalData.viewProjection = camera.viewProjection;
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