module realm.engine.dynamicobjectlayer;
import realm.engine.graphics.renderlayer;
private
{
	import realm.engine.graphics.material;
	import realm.engine.graphics.core;
	import realm.engine.graphics.batch;
	import realm.engine.asset;
	import realm.engine.core;
	import realm.engine.graphics.graphicssubsystem;
	import std.range;

}

struct ObjectRecord
{
	
}



class DynamicObjectLayer : RenderLayer
{
	private StandardShaderModel shader;
	private VertexArrayObject vao;
	private VertexBuffer!(RealmVertex,Mutable.Mutable) vertexBuffer;
	private ElementBuffer!(BufferStorageMode.Immutable) elementBuffer;
	private DrawIndirectCommandBuffer!(BufferStorageMode.Mutable) cmdBuffer;
	private ShaderStorage!(float[16],BufferStorageMode.Mutable) objectToWorldMats;
	private SamplerObject!(TextureType.TEXTURE2D)*[] textureAtlases;
	private uint numVertices;
	private uint numIndices;
	private uint numElements;
	

	override void initialize()
	{

		shader = ShaderLibrary.getShader("$EngineAssets/Shaders/blinnphong.shader");


		vao.create();
		vertexBuffer.create();
		elementBuffer.create();
		cmdBuffer.create();
		objectToWorldMats.create();
		objectToWorldMats.bindBase(2);
		vao.bind();
		vertexBuffer.bind();
		elementBuffer.bind();
		bindAttributes!(RealmVertex)();
		vertexBuffer.unbind();
		elementBuffer.unbind();
		vao.unbind();
	}

	void submitObject(Mesh mesh, Transform transform, BlinnPhongMaterial material)
	{
		uint elementOffset = 0;

		vertexBuffer[numVertices..numVertices + mesh.positions.length] = vertices;
		elementBuffer[numIndices..(numIndices)] = indices;
		uint firstIndex = 0;
		uint baseVertex = 0;
		RealmVertex[] vertices;
		vertices.length = mesh.positions.length;
		for(int i = 0; i < mesh.positions.length;i++)
		{
			RealmVertex vertex;
			vertex.position = mesh.positions[i];
			vertex.position = mesh.positions[i];
			vertex.texCoord = mesh.textureCoordinates[i];
			vertex.normal =  mesh.normals[i];
			vertex.tangent = mesh.tangents[i];
			vertex.materialId = material.instanceId;
		}
	}

}