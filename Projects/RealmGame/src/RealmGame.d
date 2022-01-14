module realm.game;
import realm.engine.app;
import std.stdio;
import realm.engine.core;
import realm.engine.debugdraw;
import realm.engine.ui.realmui;
import realm.engine.graphics.core;
import realm.engine.graphics.graphicssubsystem;
import realm.engine.graphics.renderer;
import realm.engine.graphics.material;

import std.math.trigonometry;
import std.math.constants : PI;
import glfw3.api;
import gl3n.math;
import realm.entitymanager;

//import realm.engine.graphics.core;
class RealmGame : RealmApp
{

	ShaderProgram program;

	Camera cam;
	//Renderer renderer;
	Player player;
	World world;	
	Ocean ocean;
	UIMenu menu;
	DirectionalLight mainLight;
	GameEntity plane;
	GameEntity crate;
	static IFImage crateDiffuse;
	static IFImage planeDiffuse;
	static IFImage crateNormal;
	private RealmUI.UIElement panel;
	private EntityManager manager;
	private char currentChar;

	this(int width, int height, const char* title)
	{
		
		currentChar ='`';
		super(width,height,title);
		
		manager = new EntityManager;
		cam = new Camera(CameraProjection.PERSPECTIVE,vec2(cast(float)width,cast(float)height),0.1,200,45);
		Renderer.get.activeCamera = &cam;

		player = manager.instantiate!(Player)(&cam);
		world = manager.instantiate!(World)(manager);
		menu = manager.instantiate!(UIMenu)(cam,manager);
		mainLight.transform = new Transform;
		writeln(mainLight.transform.front);
		mainLight.color = vec3(1.0,1.0,1.0);

		SimpleMaterial.initialze();
		SimpleMaterial.reserve(2);

		Renderer.get.mainLight(&mainLight);
		crate = manager.instantiate!(GameEntity)("$Assets/Models/wooden crate.obj");
		crate.getMaterial().color = vec4(1,1,1,1.0);
		crate.entityName = "Crate";
		crate.getComponent!(Transform).position = vec3(0,1,-0.5);
		crate.getComponent!(Transform).scale = vec3(0.25,0.25,0.25);
		crate.getMaterial().textures.settings = TextureDesc(ImageFormat.RGBA8,TextureFilterfunc.LINEAR,TextureWrapFunc.CLAMP_TO_BORDER);
		crate.getMaterial().textures.diffuse= new Texture2D(&crateDiffuse);
		crate.getMaterial().textures.normal= new Texture2D(&crateNormal);
		crate.getMaterial().packTextureAtlas();

		plane = manager.instantiate!(GameEntity)("$EngineAssets/Models/ui-panel.obj");
		plane.entityName = "Plane";
		plane.getComponent!(Transform).position = vec3(0,0.5,0);
		plane.getMaterial().textures.settings = TextureDesc(ImageFormat.RGBA8,TextureFilterfunc.LINEAR,TextureWrapFunc.CLAMP_TO_BORDER);
		plane.getMaterial.textures.diffuse = vec4(255);
		plane.getMaterial.textures.normal = vec4(255);
		Color!(4,ubyte) white;
		plane.getMaterial.packTextureAtlas();


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

		
		
		
	}




	override void update()
	{
		import core.thread.osthread;
		import core.time;
		import std.format;
		double time = glfwGetTime();
		double radians = glfwGetTime() *radians(150);
		double sinT =  sin(time) ;
		
		mainLight.transform.rotation =  vec3(-20,radians,0);
		manager.updateEntities();
		world.draw(Renderer.get);
		crate.draw(Renderer.get);
		plane.draw(Renderer.get);
		Renderer.get.update();

	}

}

