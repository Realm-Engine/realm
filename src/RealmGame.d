module realm.game;
import realm.engine.app;
import std.stdio;
import realm.engine.core;
import realm.entity;
import realm.engine.graphics.core;
import realm.engine.graphics.graphicssubsystem;
import realm.engine.graphics.renderer;
import realm.engine.graphics.material;
import realm.player;
import std.math.trigonometry;
import std.math.constants : PI;
import realm.world;
import glfw3.api;
import gl3n.math;

//import realm.engine.graphics.core;
class RealmGame : RealmApp
{

	ShaderProgram program;

	Camera cam;
	Renderer renderer;
	Player player;
	World world;	
	DirectionalLight mainLight;


	this(int width, int height, const char* title)
	{
		

		super(width,height,title);
		renderer = new Renderer;
		
		cam = new Camera(CameraProjection.PERSPECTIVE,vec2(cast(float)width,cast(float)height),0.1,200,45);
		renderer.activeCamera = &cam;
		player = new Player(&cam);
		world = new World;
		mainLight.transform = new Transform;
		mainLight.transform.rotation = vec3(0,-90,0);
		writeln(mainLight.transform.front);
		mainLight.color = vec3(1.0,1.0,1.0);
		//renderer.mainLight(mainLight);
		renderer.mainLight(&mainLight);
	}
	
	

	override void start()
	{
		
		
		
		
	}




	override void update()
	{
		double time = glfwGetTime() *0.5 ;
		mainLight.transform.rotation = vec3(0,sin(time) * 90,0);
		//world.getComponent!(Transform).rotation = vec3(0,sin(time),0);
		player.update();
		world.update();
		world.draw(renderer);
		renderer.update();
		

	}

}

