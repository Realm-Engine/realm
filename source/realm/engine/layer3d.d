module realm.engine.layer3d;
import realm.engine.graphics.core;
import gl3n.linalg;
import realm.engine.core;
import realm.engine.graphics.opengl;
import realm.engine.graphics.material;

class Layer3D
{
	private VertexBuffer!(vec3, BufferStorageMode.Mutable) vbo;
	private ElementBuffer!(BufferStorageMode.Mutable) ibo;
	private VertexArrayObject vao;
	private UniformBuffer ubo;
	private VertexAtrrib[2] vertexLayout;
	

	this()
	{
		vbo.create();
		ibo.create();
		vao.create();
		ubo.create("PerObjectData");
		vertexLayout[0] = {VertexType.FLOAT3,VertexSlot.POSITION;};
		vertexLayout[1] = {VertexType.FLOAT3,VertexSlot.NORMAL;};



		

	}
	
	private void bindAttributes(Mesh mesh)
	{
		import realm.engine.graphics.opengl : bindAttribute;
		int index = 0;
		foreach(attrib; vertexLayout)
		{

		}
		//bindAttribute!(vec3)(0,0,0);
	}

	void setupDraw()
	{
		

	}

	void drawTo(Mesh mesh,MaterialData mat,Transform transform)
	{
		import derelict.opengl3.gl3; 
		vao.bind();
		vbo.bind();
		ibo.bind();
		//ubo.bind();
		mat.shader.use();
		bindAttributes(mesh);
		ubo.bindBuffer(mat.shader);
		
		ubyte[] builDataStruct()
		{
			ubyte[] result;
			result ~= mat.dataBlock[0..mat.layoutTypeInfo.tsize];
			result ~= cast(ubyte[])(transform.transformation.transposed.value_ptr[0..16]);
			return result;
		}
		ubo.setData!(ubyte)(builDataStruct());
		ubo.unbind();
		
		vbo[0..mesh.positions.length] = mesh.positions;
		ibo[0..mesh.faces.length] = mesh.faces;

		glDrawElements(GL_TRIANGLES,cast(int)mesh.faces.length,GL_UNSIGNED_INT,cast(const void*)0);


	}
}