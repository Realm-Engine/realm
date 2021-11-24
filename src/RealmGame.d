module realm.game;
import realm.engine.app;
import std.stdio;
import realm.engine.core;
import gl3n.linalg;
import realm.entity;
import realm.resource;
import realm.engine.graphics;
import realm.engine.containers;


class RealmGame : RealmApp
{
	Entity entity;
	shared(ShaderProgram) shader;
	Queue!int queue;
	this(int width, int height, const char* title)
	{
		shader = new shared(ShaderProgram);
		Mesh mesh = new Mesh;
		super(width,height,title);
		vec3[] triangle = [vec3(-0.5f,-0.5f,0),vec3(0.5,-0.5f,0),vec3(0.5,0.5f,0),vec3(-0.5,0.5f,0.0f)];
		uint[] faces = [0,1,2,2,3,0];
		mesh.positions = triangle;
		mesh.faces = faces;
		mesh.calculateNormals();
		Transform transform = new Transform;	
		
		entity = new Entity(mesh,transform);

		renderer.compileShaderProgram(vertexShader,fragmentShader,&shader);
		renderer.useShaderProgram(&shader);

	}

	override void update()
	{
		renderer.beginDraw();
		mat4 model = entity.transform.model;
		renderer.drawMesh(entity.mesh,model);
		
		renderer.endDraw();
	}

}

