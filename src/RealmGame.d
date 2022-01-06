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
import realm.gameentity;
//import realm.engine.graphics.core;
class RealmGame : RealmApp
{

	ShaderProgram program;

	Camera cam;
	Renderer renderer;
	Player player;
	World world;	
	DirectionalLight mainLight;
	GameEntity crate;
	GameEntity plane;

	this(int width, int height, const char* title)
	{
		

		super(width,height,title);
		renderer = new Renderer;

		cam = new Camera(CameraProjection.PERSPECTIVE,vec2(cast(float)width,cast(float)height),0.1,200,45);
		renderer.activeCamera = &cam;
		player = new Player(&cam);
		world = new World;
		mainLight.transform = new Transform;
		mainLight.transform.rotation = vec3(-90,0,0);
		writeln(mainLight.transform.front);
		mainLight.color = vec3(1.0,1.0,1.0);
		//renderer.mainLight(mainLight);
		SimpleMaterial.initialze();
		SimpleMaterial.reserve(2);
		renderer.mainLight(&mainLight);
		crate = new GameEntity("./Assets/Models/wooden_box_obj.obj");
		plane = new GameEntity("./Assets/Models/plane.obj");
		
		crate.getComponent!(Transform).scale = vec3(0.01,0.01,0.01);
		crate.getComponent!(Transform).position = vec3(0,0.5,-0.7);
		crate.color = vec4(0.7,0.2,0.3,1.0);
		plane.color = vec4(0.1,0.5,0.2,1.0);
		
		
		
		
	}
	
	

	override void start()
	{
		
		
		
		
	}




	override void update()
	{
		double time = glfwGetTime() *radians(150) ;
		
		//world.getComponent!(Transform).rotation = vec3(0,sin(time),0);
		player.update();
		crate.update();
		plane.update();
		//world.update();
		crate.draw(renderer);
		plane.draw(renderer);
		
		
		//world.draw(renderer);
		renderer.update();
		

	}

}

