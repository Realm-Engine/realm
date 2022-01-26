module realm.mainstate;
import realm.engine.app;
import std.stdio;
import realm.engine.core;
import realm.engine.debugdraw;
import realm.engine.ui.realmui;
import realm.engine.graphics.core;
import realm.engine.graphics.graphicssubsystem;
import realm.engine.graphics.renderer;
import realm.engine.graphics.material;
import realm.entitymanager;
import realm.fsm.statemachine;
import realm.fsm.gamestate;
import gl3n.linalg;
import glfw3.api;
class MainState : GameState
{
	private Player player;
	private World world;	
	private Ocean ocean;
	private UIMenu menu;
	private DirectionalLight mainLight;
	private GameEntity plane;
	private GameEntity crate;
	private static IFImage crateDiffuse;
	private static IFImage planeDiffuse;
	private static IFImage crateNormal;
	private EntityManager manager;
	private Camera cam;
	private int worldSeed;
	this(EntityManager manager)
	{
		this.worldSeed = worldSeed;
		this.manager = manager;
		this.cam = *Renderer.get.activeCamera;
	}

	override void enter()
	{
		mainLight.transform = new Transform;
		mainLight.color = vec3(1.0,1.0,1.0);

		crateDiffuse = readImageBytes("$Assets/Images/crate/crate_BaseColor.png");
		crateNormal = readImageBytes("$Assets/Images/crate/crate_Normal.png");


		SimpleMaterial.initialze();
		SimpleMaterial.reserve(2);


		Renderer.get.mainLight(&mainLight);

		player = manager.instantiate!(Player)(&cam);
		world = manager.instantiate!(World)(manager);

		menu = manager.instantiate!(UIMenu)(cam,manager);
		crate = manager.instantiate!(GameEntity)("$Assets/Models/wooden crate.obj");
		//menu.active = false;
		crate.getMaterial().color = vec4(1,1,1,1.0);
		crate.entityName = "Crate";
		crate.getComponent!(Transform).position = vec3(0,1,-6);
		crate.getComponent!(Transform).scale = vec3(0.25,0.25,0.25);
		crate.getMaterial().textures.settings = TextureDesc(ImageFormat.SRGBA8,TextureFilterfunc.LINEAR,TextureWrapFunc.CLAMP_TO_BORDER);
		crate.getMaterial().textures.diffuse= new Texture2D(&crateDiffuse);
		crate.getMaterial().textures.normal= new Texture2D(&crateNormal);
		crate.getMaterial().packTextureAtlas();

		plane = manager.instantiate!(GameEntity)("$EngineAssets/Models/ui-panel.obj");
		plane.entityName = "Plane";
		plane.getComponent!(Transform).position = vec3(0,0.5,0);
		plane.getComponent!(Transform).rotation = vec3(90,0,0);
		plane.getMaterial().textures.settings = TextureDesc(ImageFormat.SRGBA8,TextureFilterfunc.LINEAR,TextureWrapFunc.CLAMP_TO_BORDER);
		plane.getMaterial.textures.diffuse = Vector!(ubyte,4)(255);
		plane.getMaterial.textures.normal = Vector!(ubyte,4)(0);
		plane.active = false;

		plane.getMaterial.packTextureAtlas();
		


		

		scope(exit)
		{
			crateDiffuse.free();
			planeDiffuse.free();
			crateNormal.free();
		}
	}

	override void update()
	{
		double time = glfwGetTime();
		double radians = glfwGetTime() *radians(150);
		double sinT =  sin(time) ;
		mainLight.transform.rotation =  vec3(-20,radians,0);
		world.draw(Renderer.get);
		crate.draw(Renderer.get);
		plane.draw(Renderer.get);
	}
	
	override void finish()
	{

	}

}