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
	private VertexBuffer!(RealmVertex,BufferStorageMode.Mutable) vertexBuffer;
	private ElementBuffer!(BufferStorageMode.Mutable) elementBuffer;
	private DrawIndirectCommandBuffer!(BufferStorageMode.Mutable) cmdBuffer;
	private ShaderStorage!(float[16],BufferStorageMode.Mutable) objectToWorldMats;
	private SamplerObject!(TextureType.TEXTURE2D)*[] textureAtlases;
	private uint numVertices;
	private uint numIndices;
	private uint numObjects;
	

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
		vertexBuffer[numVertices..numVertices + mesh.positions.length] = vertices;
		elementBuffer[numIndices..(numIndices)] = mesh.faces;
		
		DrawElementsIndirectCommand cmd;
		cmd.count = cast(uint)mesh.faces.length;
		cmd.instanceCount = cast(uint)mesh.faces.length / 3;
		cmd.firstIndex = numIndices;
		cmd.baseVertex = numVertices;
		cmd.baseInstance  = 0;
		cmdBuffer[numObjects] = cmd;
		numObjects++;
		numVertices += vertices.length;
		numIndices += mesh.faces.length;
		material.writeUniformData();
		textureAtlases~=material.getTextureAtlas();
		mat4 objectToWorld = transform.transformation;
		float[16] objectToWorldData = objectToWorld.value_ptr[0..16].dup;
		objectToWorldMats[material.instanceId] = objectToWorldData;
		

	}
	void onDraw(string RenderpassName,Renderpass)(Renderpass pass) if(RenderpassName == "geometryPass" || RenderpassName == "lightPass")
	{
		shader.use();
		pass.bindAttachments(shader);
		vao.bind();
		vertexBuffer.bind();
		elementBuffer.bind();
		cmdBuffer.bind();
		foreach(i,texture; textureAtlases.enumerate(0))
		{
			texture.setActive();
			shader.setUniformInt(texture.slot,texture.slot);

		}
		objectToWorldMats.bindBase(2);
		BlinnPhongMaterial.bindShaderStorage();
		GraphicsSubsystem.drawMultiElementsIndirect!(PrimitiveShape.TRIANGLE)(0,numObjects);
		vertexBuffer.clear();
		elementBuffer.clear();
		cmdBuffer.clear();
		objectToWorldMats.clear();
		shader.unbind();
		vao.unbind();
		vertexBuffer.unbind();
		elementBuffer.unbind();
		cmdBuffer.unbind();
		
	}

}