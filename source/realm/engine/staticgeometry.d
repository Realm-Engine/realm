module realm.engine.staticgeometry;
import realm.engine.graphics.renderlayer;
private
{
	import realm.engine.graphics.material;
	import realm.engine.graphics.core;
	import realm.engine.graphics.batch;
	import realm.engine.asset;
	import realm.engine.core;
	
}
private static StandardShaderModel geoShader;


struct GeometryList
{
	Mesh[] meshes;
	Transform[] transforms;	
	BlinnPhongMaterial[] materials;

}



class StaticGeometryLayer : RenderLayer
{
	
	
	private VertexArrayObject vao;
	private VertexBuffer!(RealmVertex,BufferStorageMode.Immutable) vertexBuffer;
	private ElementBuffer!(BufferStorageMode.Immutable) elementBuffer;
	private DrawIndirectCommandBuffer!(BufferStorageMode.Immutable) cmdBuffer;
	private ShaderStorage!(float[16],BufferStorageMode.Immutable) objectToWorldMats;
	private SamplerObject!(TextureType.TEXTURE2D)*[] textureAtlases;
	private uint numVertices;
	private uint numIndices;

	void bindAttributes()
	{
		import realm.engine.graphics.opengl : bindAttribute;
		import std.meta;
		RealmVertex vertex;
		uint stride = 0;

		stride += RealmVertex.sizeof;

		int offset = 0;
		int index = 0;
		static foreach(member; __traits(allMembers,RealmVertex))
		{

			bindAttribute!(Alias!(typeof(__traits(getMember,vertex,member))))(index,offset,stride);
			index += 1;
			offset += (typeof(__traits(getMember,vertex,member))).sizeof;
		}
	}

	override void initialize()
	{
		if(geoShader is null)
		{
			geoShader = loadShaderProgram("$EngineAssets/Shaders/blinnphong.shader","Blinn Phong");
			
		}
		vao.create();
		vertexBuffer.create();
		elementBuffer.create();
		cmdBuffer.create();
		objectToWorldMats.create();
		objectToWorldMats.bindBase(2);
	}

	private void allocateGraphicsMemory(uint numVertices, uint numIndices, uint numElements)
	{
		vertexBuffer.bind();
		elementBuffer.bind();
		cmdBuffer.bind();
		bindAttributes();
		vertexBuffer.store(numVertices);
		elementBuffer.store(numIndices);
		cmdBuffer.store(numElements);
		vertexBuffer.unbind();
		elementBuffer.unbind();
		cmdBuffer.unbind();
		objectToWorldMats.store(numElements);
	}

	private void submitGeometryList(GeometryList geoList, out uint numVertices, out uint numIndices)
	{
		RealmVertex[] vertices;
		uint[] indices;

		for(int i = 0; i < geoList.meshes.length;i++)
		{
			Mesh mesh = geoList.meshes[i];
			numVertices += mesh.positions.length;
			numIndices += mesh.faces.length;
		}
		
		allocateGraphicsMemory(numVertices,numIndices,cast(uint)geoList.meshes.length);
		
	}
	private void fillBuffers(ref GeometryList geoList,ref RealmVertex[] vertices, ref uint[] indices)
	{
		uint elementOffset = 0;
		
		vertexBuffer[0..numVertices] = vertices;
		elementBuffer[0..numIndices] = indices;
		uint firstIndex = 0;
		uint baseVertex = 0;
		for(int i = 0; i < geoList.meshes.length;i++)
		{
			Mesh mesh = geoList.meshes[i];
			DrawElementsIndirectCommand cmd;
			cmd.count = cast(uint)mesh.faces.length;
			cmd.instanceCount = cast(uint)mesh.faces.length / 3;
			cmd.firstIndex = firstIndex;
			cmd.baseVertex = baseVertex;
			cmd.baseInstance = 0;
			cmdBuffer[i] = cmd;

			mat4 objectToWorld = geoList.transforms[i].transformation;
			BlinnPhongMaterial material = geoList.materials[i];
			material.writeUniformData();
			textureAtlases ~= material.getTextureAtlas();
			float[16]* objectToWorldPtr = &objectToWorldMats.ptr[material.instanceId];
			*objectToWorldPtr = objectToWorld.value_ptr[0..16].dup;

		}

	}

	override void flush()
	{
		
	}

}

