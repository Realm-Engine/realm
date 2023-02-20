module realm.engine.layer3d;
import realm.engine.graphics.core;
import gl3n.linalg;
import realm.engine.core;
import realm.engine.graphics.opengl;
import realm.engine.graphics.material;

import realm.engine.memory.core;

struct Vertex3D
{
	
	@VertexAtrribute(false,false) vec3 position;

	
	@VertexAtrribute(true,false) vec3 normal;
	@VertexAtrribute(false,false) vec2 texCoord;
}

class Layer3D
{
	private VertexBuffer!(Vertex3D, BufferStorageMode.Mutable) vbo;
	private ElementBuffer!(BufferStorageMode.Mutable) ibo;
	private VertexArrayObject vao;
	private UniformBuffer ubo;
	
	

	this()
	{
		vbo.create();
		ibo.create();
		vao.create();
		ubo.create("PerObjectData");
		vbo.attribFormat(vao);
		
		
	}
	
	

	void setupDraw()
	{
		

	}

	void drawTo(Mesh mesh,MaterialData mat,Transform transform)
	{
		import derelict.opengl3.gl3; 
		int i,unit;
		vao.bind();
		vbo.bind();
		ibo.bind();
		//ubo.bind();
		mat.shader.use();
		//bindAttributes(mesh);
		ubo.bindBuffer(mat.shader);
		
		ubyte[] buildDataStruct()
		{
			ubyte[] result;
			result ~= mat.dataBlock[0..mat.layoutTypeInfo.tsize];
			result ~= cast(ubyte[])(transform.transformation.transposed.value_ptr[0..16]);
			return result;
		}
		ubo.setData!(ubyte)(buildDataStruct());
		ubo.unbind();
		
		Vertex3D[] vertices;
		vertices.length = mesh.positions.length;
		for( i = 0; i< mesh.positions.length; i++)
		{
			vertices[i].position = mesh.positions[i];
			vertices[i].normal = mesh.normals[i];
			vertices[i].texCoord = mesh.textureCoordinates[i];
		}
		
		for( i = 0; i< mat.numTextures;i++)
		{
			uint location = mat.textureLocations[i];
			Sampler sampler = mat.samplers[i];
			mat.shader.setUniformInt(location,unit);
			sampler.bind(TextureType.TEXTURE2D,unit,mat.textures[i]);
			unit++;
		}
		
		

		vbo[0..mesh.positions.length] = vertices;
		ibo[0..mesh.faces.length] = mesh.faces;

		glDrawElements(GL_TRIANGLES,cast(int)mesh.faces.length,GL_UNSIGNED_INT,cast(const void*)0);
		vbo.unbind();
		ibo.unbind();
		vao.unbind();
		for( i = 0; i< mat.numTextures;i++)
		{
			uint textureId = mat.textures[i];
			int uniform = mat.textureLocations[i];
			Sampler sampler = mat.samplers[i];
			sampler.unbind(TextureType.TEXTURE2D);
			

		}
		//MemoryUtil.freeChunk(vertices.ptr);


	}
}