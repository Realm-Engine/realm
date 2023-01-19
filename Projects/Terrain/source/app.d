import std.stdio;
import realm.engine.app;
import realm.engine.graphics.renderer;
import realm.engine.core;
import realm.engine.graphics.core;
import realm.engine.terrain;
class Game : RealmApp
{
	private Camera cam;
	private Skybox skybox;
	private TerrainLayer terrainLayer;
	this(int width, int height, const char* title,string[] args)
	{
		super(width,height,title,args);
	}
	
	override void start()
	{
		auto windowSize = getWindowSize();
		cam = new Camera(CameraProjection.PERSPECTIVE,vec2(cast(float)windowSize[0],cast(float)windowSize[1]) / 1,0.1,750,60);
		Renderer.get.activeCamera = &cam;
		initSkybox(vec4(0.4,0.5,0.1,1.0));
		
		
	}

	void initSkybox(vec4 color)
	{
		skybox = new Skybox(color);
		Renderer.get.setSkybox(skybox);



	}

	override void update()
	{
		Renderer.get.update();
	}

}

void main(string[] args)
{
	Game game = new Game(1024,768,"Terrain",args);
	game.run();
	scope(exit)
	{
		game.destroy();
	}
	writeln("Edit source/app.d to start your project.");
}
