module realm.game;
import realm.engine.app;
import std.stdio;
import realm.engine.core;
import gl3n.linalg;
class RealmGame : RealmApp
{
	Mesh mesh;
	this(int width, int height, const char* title)
	{
		mesh = new Mesh;
		super(width,height,title);
		vec3[] triangle = [vec3(-0.5f,-0.5f,0),vec3(0.5,-0.5f,0),vec3(0.5,0.5f,0),vec3(-0.5,0.5f,0.0f)];
		uint[] faces = [0,1,2,2,3,0];
		mesh.positions = triangle;
		mesh.faces = faces;
		mesh.calculateNormals();
		
	}

	override void update()
	{
		renderer.beginDraw();
		
		renderer.drawMesh(mesh);
		
		renderer.endDraw();
	}

}

