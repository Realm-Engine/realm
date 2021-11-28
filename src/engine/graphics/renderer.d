module realm.engine.graphics.renderer;
import realm.engine.graphics.batch;
import realm.engine.graphics.graphicssubsystem;
import realm.engine.graphics.core;
import realm.engine.core;
import gl3n.linalg;
class Renderer
{
	import std.container.array;
	private Batch!RealmVertex batch;
	VertexAttribute[] vertex3DAttributes;
	private RealmGlobalData globalData;

	this()
	{
		
		GraphicsSubsystem.initialze();
		
		globalData.viewProjection = mat4.identity;
		GraphicsSubsystem.updateGlobalData(&globalData);
		VertexAttribute position = {VertexType.FLOAT3,0,0,AttributeSlot.POSITION};
		/*VertexAttribute normal = {VertexType.FLOAT3,1,12,AttributeSlot.POSITION};
		VertexAttribute texcoord = {VertexType.FLOAT3,2,24,AttributeSlot.POSITION};*/
		vertex3DAttributes ~= position;
		/*vertex3DAttributes ~= normal;
		vertex3DAttributes ~= texcoord;*/
		batch = new Batch!RealmVertex(MeshTopology.TRIANGLE);
		batch.initialize(vertex3DAttributes,32);
		batch.reserve(1);

	}

	void submitMesh(Mesh mesh)
	{
		batch.bindBuffers();
		
		RealmVertex[uint] vertexData;
		foreach(index; mesh.faces)
		{
			RealmVertex vertex;
			vertex.position = mesh.positions[index];
			/*vertex.normal = mesh.normals[index];
			vertex.uv = mesh.textureCoordinates[index];*/
			vertexData[index] = vertex;
			



		}
		//batch.allocateBuffers(cast(uint)vertexData.length);
		batch.submitVertices(vertexData.values,mesh.faces);

		batch.unbindBuffers();
		
	}

	void flush()
	{
		batch.drawBatch();
	}

	

}