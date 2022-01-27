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
import realm.fsm.statemachine;
import realm.fsm.gamestate;
import realm.mainstate;
import realm.mainmenu;
//import realm.engine.graphics.core;
class RealmGame : RealmApp
{



	Camera cam;
	//Renderer renderer;


	private EntityManager manager;
	private char currentChar;
	private StateMachine _stateMachine;

	this(int width, int height, const char* title)
	{
		
		super(width,height,title);

		//enableDebugging();
		manager = new EntityManager;
		cam = new Camera(CameraProjection.PERSPECTIVE,vec2(cast(float)width,cast(float)height) / 1,1,750,60);
		Renderer.get.activeCamera = &cam;
		VirtualFS.registerPath!("Projects/RealmGame/Assets")("Assets");
		RealmUI.themePush(RealmUI.UITheme(vec4(1),vec4(0,0,0,1)));


		_stateMachine = manager.instantiate!(StateMachine)();
		//_stateMachine.pushState(new MainState(manager,cam));
		_stateMachine.pushState(new MainMenu(manager));
	}

	static this()
	{
		
		
	}
	
	

	override void start()
	{

		
		
		
	}




	override void update()
	{
		import core.thread.osthread;
		import core.time;
		import std.format;
		
		
		
		manager.updateEntities();
		//_stateMachine.top().update();
		Renderer.get.update();

	}

}

