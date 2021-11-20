module realm.game;
import realm.engine.app;
import std.stdio;
class RealmGame : RealmApp
{
	this(int width, int height, const char* title)
	{
		super(width,height,title);
	}
	override void update()
	{
		renderer.beginDraw();
		immutable float[] triangle = [-0.5f,-0.5f,0
									  ,0.5,-0.5f,0,
									  0.5,0.5f,0,
									  -0.5f,0.5f,0.0f];
		immutable uint[] faces = [0,1,2,2,3,0];
		renderer.drawMesh(triangle,faces);
		renderer.endDraw();
	}
}

