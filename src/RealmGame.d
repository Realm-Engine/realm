module realm.game;
import realm.engine.app;
import std.stdio;
import realm.engine.core;
import gl3n.linalg;
import realm.entity;
import realm.engine.graphics.core;
import realm.engine.graphics.graphicssubsystem;
import realm.engine.graphics.renderer;
import std.file : read;
import realm.engine.graphics.material;
import std.meta;
import realm.engine.ecs;
import realm.engine.asset;
import imagefmt;
import realm.engine.logging;
import realm.engine.input;
import realm.player;
import std.math.trigonometry;
import std.math.constants : PI;
import realm.world;
//import realm.engine.graphics.core;
class RealmGame : RealmApp
{

	ShaderProgram program;

	Camera cam;
	Renderer renderer;
	Player player;
	World world;	



	this(int width, int height, const char* title)
	{
		

		super(width,height,title);
		renderer = new Renderer;
		renderer.activeCamera = &cam;
		cam = new Camera(CameraProjection.PERSPECTIVE,vec2(cast(float)width,cast(float)height),100,-1.,45);
		player = new Player(&cam);
		world = new World;

	}
	
	

	override void start()
	{
		
		
		
		
	}

	override void update()
	{
		player.update();
		world.update();
		world.draw(renderer);
		renderer.update();

	}

}

