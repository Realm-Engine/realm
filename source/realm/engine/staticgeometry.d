module realm.engine.staticgeometry;
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



struct GeometryList
{
	Mesh[] meshes;
	Transform[] transforms;	
	BlinnPhongMaterial[] materials;

}



class StaticGeometryLayer : RenderLayer
{
	
	private StandardShaderModel geoShader;
	private VertexArrayObject vao;
	private VertexBuffer!(RealmVertex,BufferStorageMode.Immutable) vertexBuffer;
	private ElementBuffer!(BufferStorageMode.Immutable) elementBuffer;
	private DrawIndirectCommandBuffer!(BufferStorageMode.Immutable) cmdBuffer;
	private ShaderStorage!(float[16],BufferStorageMode.Immutable) objectToWorldMats;
	private SamplerObject!(TextureType.TEXTURE2D)*[] textureAtlases;
	private uint numVertices;
	private uint numIndices;
	private uint numElements;
	

	override void initialize()
	{

		geoShader = ShaderLibrary.getShader("$EngineAssets/Shaders/blinnphong.shader");
			

		vao.create();
		vertexBuffer.create();
		elementBuffer.create();
		cmdBuffer.create();
		objectToWorldMats.create();
		objectToWorldMats.bindBase(2);
	}

	private void allocateGraphicsMemory(uint numVertices, uint numIndices, uint numElements)
	{
		vao.bind();
		vertexBuffer.bind();
		elementBuffer.bind();
		cmdBuffer.bind();
		bindAttributes!(RealmVertex)();
		vertexBuffer.store(numVertices);
		elementBuffer.store(numIndices);
		cmdBuffer.store(numElements);
		vertexBuffer.unbind();
		elementBuffer.unbind();
		cmdBuffer.unbind();

		objectToWorldMats.store(numElements);
		vao.unbind();
	}

	public void submitGeometryList(GeometryList geoList)
	{
		RealmVertex[] vertices;
		uint[] indices;
		//vertices.length = geoList.meshes.length;
		for(int i = 0; i < geoList.meshes.length;i++)
		{
			numElements++;
			Mesh mesh = geoList.meshes[i];

			for(int j = 0; j < mesh.positions.length;j++)
			{
				RealmVertex vertex;

				
				
				vertex.position = mesh.positions[j];
				vertex.texCoord = mesh.textureCoordinates[j];
				vertex.normal =  mesh.normals[j];
				vertex.tangent = mesh.tangents[j];
				vertex.materialId = geoList.materials[i].instanceId;
				vertices ~= vertex;
			}
			
			indices.length = indices.length + mesh.faces.length;
			indices[numIndices..numIndices + mesh.faces.length] = mesh.faces;
			numVertices += mesh.positions.length;
			numIndices += mesh.faces.length;
			

		}
		
		allocateGraphicsMemory(numVertices,numIndices,cast(uint)geoList.meshes.length);
		fillBuffers(geoList,vertices,indices);
		
	}
	private void fillBuffers( GeometryList geoList, RealmVertex[] vertices,  uint[] indices)
	{
		uint elementOffset = 0;
		
		vertexBuffer[0..(numVertices)] = vertices;
		elementBuffer[0..(numIndices)] = indices;
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
			geoList.transforms[i].updateTransformation();
			mat4 objectToWorld = geoList.transforms[i].transformation;
			BlinnPhongMaterial material = geoList.materials[i];
			material.writeUniformData();
			textureAtlases ~= material.getTextureAtlas();
			float[16]* objectToWorldPtr = &objectToWorldMats.ptr[material.instanceId];
			*objectToWorldPtr = objectToWorld.value_ptr[0..16].dup;
			firstIndex += mesh.faces.length;
			baseVertex += mesh.positions.length;

		}

	}

	

	void onDraw(string RenderpassName,Renderpass)(Renderpass pass) if(RenderpassName == "geometryPass" || RenderpassName == "lightPass")
	{
		

		geoShader.use();
		pass.bindAttachments(geoShader);
		vao.bind();
		vertexBuffer.bind();
		elementBuffer.bind();
		cmdBuffer.bind();
		foreach(i,texture; textureAtlases.enumerate(0))
		{
			texture.setActive();
			geoShader.setUniformInt(texture.slot,texture.slot);

		}
		objectToWorldMats.bindBase(2);
		BlinnPhongMaterial.bindShaderStorage();
		GraphicsSubsystem.drawMultiElementsIndirect!(PrimitiveShape.TRIANGLE)(0,numElements);
		geoShader.unbind();
		vao.unbind();
		vertexBuffer.unbind();
		elementBuffer.unbind();
		cmdBuffer.unbind();

		
	}

}

