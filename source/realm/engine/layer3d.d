module realm.engine.layer3d;
import realm.engine.graphics.core;
import gl3n.linalg;
import realm.engine.core;
import realm.engine.graphics.opengl;
class Layer3D
{
	private VertexBuffer!(vec3, BufferStorageMode.Mutable) vbo;
	private ElementBuffer!(BufferStorageMode.Mutable) ibo;
	private VertexArrayObject vao;
	private UniformBuffer ubo;

	this()
	{
		vbo.create();
		ibo.create();
		vao.create();
		ubo.create();

		

	}

	private void bindAttributes(Mesh mesh)
	{
		import realm.engine.graphics.opengl : bindAttribute;
		bindAttribute!(vec3)(0,0,0);
	}

	void drawTo(Material)(Mesh mesh,Material mat)
	{
		import derelict.opengl3.gl3; 
		vao.bind();
		vbo.bind();
		ibo.bind();
		bindAttributes(mesh);
		ubo.bindBuffer(mat.program,1);
		ubo.setData!(Material.UniformLayout.UserData)(mat.layout);
		vbo[0..mesh.positions.length] = mesh.positions;
		ibo[0..mesh.faces.length] = mesh.faces;

		glDrawElements(GL_TRIANGLES,cast(int)mesh.faces.length,GL_UNSIGNED_INT,cast(const void*)0);


	}
}