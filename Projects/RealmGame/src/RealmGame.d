module realm.game;
import realm.engine.app;
import std.stdio;
import realm.engine.core;

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
import realm.engine.debugdraw;
import realm.engine.ui;
import realm.ocean;
//import realm.engine.graphics.core;
class RealmGame : RealmApp
{

	ShaderProgram program;

	Camera cam;
	//Renderer renderer;
	Player player;
	World world;	
	DirectionalLight mainLight;
	GameEntity plane;
	GameEntity crate;
	static IFImage crateDiffuse;
	static IFImage planeDiffuse;
	static IFImage crateNormal;
	private RealmUI.UIElement panel;
	mixin EntityRegistry!(World,GameEntity,Ocean,Player);

	EntityManager manager;
	this(int width, int height, const char* title)
	{
		

		super(width,height,title);
		
		manager = new EntityManager;
		cam = new Camera(CameraProjection.PERSPECTIVE,vec2(cast(float)width,cast(float)height),0.1,200,45);
		Renderer.get.activeCamera = &cam;
		player = manager.instantiate!(Player)(&cam);
		world = manager.instantiate!(World)();

		mainLight.transform = new Transform;
		writeln(mainLight.transform.front);
		mainLight.color = vec3(1.0,1.0,1.0);

		SimpleMaterial.initialze();
		SimpleMaterial.reserve(2);

		Renderer.get.mainLight(&mainLight);
		crate = manager.instantiate!(GameEntity)("$Assets/Models/wooden crate.obj");

		crate.getMaterial().color = vec4(1,1,1,1.0);
		crate.getComponent!(Transform).position = vec3(0,0.5,-0.5);
		crate.getComponent!(Transform).scale = vec3(0.25,0.25,0.25);
		crate.getMaterial().textures.settings = TextureDesc(ImageFormat.RGBA8,TextureFilterfunc.LINEAR,TextureWrapFunc.CLAMP_TO_BORDER);
		crate.getMaterial().textures.diffuse= new Texture2D(&crateDiffuse,crate.getMaterial().textures.settings);
		crate.getMaterial().textures.normal= new Texture2D(&crateNormal,crate.getMaterial().textures.settings);
		crate.getMaterial().packTextureAtlas();

		scope(exit)
		{
			crateDiffuse.free();
			planeDiffuse.free();
			crateNormal.free();
		}
		
		
		
	}

	static this()
	{
		VirtualFS.registerPath!("Projects/RealmGame/Assets")("Assets");
		crateDiffuse = readImageBytes("$Assets/Images/crate/crate_BaseColor.png");
		//planeDiffuse = readImageBytes("./Assets/Images/texture_0.png");
		crateNormal = readImageBytes("$Assets/Images/crate/crate_Normal.png");
	}
	
	

	override void start()
	{
		panel = RealmUI.createElement(vec3(-1150,0,0),vec3(300,600,1),vec3(0,0,0));
		
		
		
	}




	override void update()
	{

		double time = glfwGetTime();
		double radians = glfwGetTime() *radians(150);
		double sinT =  sin(time) ;
		
		mainLight.transform.rotation =  vec3(-20,radians,0);
		player.update();
		world.update();
		crate.update();
		//plane.update();
		
		world.draw(Renderer.get);
		crate.draw(Renderer.get);
		//plane.draw(renderer);
		RealmUI.drawPanel(panel,vec4(53,61,97,0.9));
		Renderer.get.update();
		

	}

}

