module realm.uimenu;

import realm.engine.ui.realmui;
import realm.engine.core;
import realm.engine.app;
import realm.engine.ecs;
import realm.entitymanager;
class UIMenu
{

	private RealmUI.UIElement cameraInfo;
	private Camera camera;
	private RealmUI.UIElement mouseInfo;
	private RealmUI.UIElement button;
	private RealmUI.UIElement infoPanel;
	private RealmUI.UIElement entityName;
	private RealmUI.UIElement nextEntity;
	private RealmUI.UIElement lastEntity;
	private RealmUI.UIElement toggleActive;
	private RealmUI.UIElement generateMapButton;
	private RealmUI.UIElement input;
	private EntityManager entityManager;
	private int currentEntity;
	private vec4 color = vec4(24,24,25,1);
	mixin RealmEntity!("Menu");
	void start(Camera camera,EntityManager entityManager)
	{
		currentEntity = 0;
		this.camera = camera;
		this.entityManager = entityManager;
		cameraInfo =  RealmUI.createElement(vec3(150,680,1),vec3(300,12,1),vec3(0,0,0));
		mouseInfo =  RealmUI.createElement(vec3(150,630,1),vec3(300,12,1),vec3(0,0,0));
		button = RealmUI.createElement(vec3(0,-100,0),vec3(150,25,1),vec3(0));
		infoPanel = RealmUI.createElement(vec3(75,200,1),vec3(150,400,1),vec3(0));
		entityName = RealmUI.createElement(vec3(0,150,0),vec3(100,35,1),vec3(0));

		nextEntity = RealmUI.createElement(vec3(50,100,0),vec3(50,25,1),vec3(0));
		lastEntity = RealmUI.createElement(vec3(-50,100,0),vec3(50,25,1),vec3(0));
		toggleActive = RealmUI.createElement(vec3(0,50,0),vec3(100,25,1),vec3(0));
		generateMapButton = RealmUI.createElement(vec3(600,50,0),vec3(100,50,1),vec3(0));
		input = RealmUI.createElement(vec3(0,25,0),vec3(100,25,1),vec3(0));

		button.textLayout = RealmUI.TextLayout(4,6,24);
		

	}

	void drawInfoPanel()
	{

		RealmUI.drawPanel(infoPanel);
		RealmUI.containerPush(infoPanel);
		GameEntity[] gameEntities = entityManager.getEntities!(GameEntity)();
		World gameWorld = entityManager.getEntities!(World)()[0];

		if(RealmUI.button(button,"Press me!") == RealmUI.ButtonState.PRESSED)
		{
			Logger.LogInfo("Button pressed");
		}
		if(RealmUI.button(nextEntity,"Next") == RealmUI.ButtonState.PRESSED )
		{
			if(currentEntity < gameEntities.length-1)
			{
				currentEntity++;
			}
		}
		if(RealmUI.button(lastEntity,"Prev") == RealmUI.ButtonState.PRESSED )
		{
			if(currentEntity > 0)
			{
				currentEntity--;
			}
		}
		GameEntity entity = gameEntities[currentEntity];
		if(RealmUI.button(toggleActive,"Toggle",) == RealmUI.ButtonState.PRESSED)
		{
			entity.active = entity.active ^ true;
		}
		RealmUI.drawTextString(entityName,entity.entityName);
		RealmUI.textBox(input);
		RealmUI.containerPop();
		//if(RealmUI.button(generateMapButton,"Generate",) == RealmUI.ButtonState.PRESSED)
		//{
		//    gameWorld.generateWorld();
		//}
	}

	void update()
	{
		import std.stdio;
		if(active)
		{	
			
			double mouseX = InputManager.getMouseAxis(MouseAxis.X);
			double mouseY = InputManager.getMouseAxis(MouseAxis.Y);
			auto windowSize = RealmApp.getWindowSize();
			//mouseY -= ( * cast(double)windowSize[1]);
			mouseY = ((1 - (mouseY/cast(double)windowSize[1])) * windowSize[1]);

			//RealmUI.drawTextString(cameraInfo, RealmUI.TextLayout(4,6,12),"Camera X: %.2f Y: %.2f Z: %.2f",camera.position.x,camera.position.y,camera.position.z);
			//RealmUI.drawTextString(mouseInfo, RealmUI.TextLayout(4,6,12),"Mouse X: %.2f Y: %.2f",mouseX,mouseY);
			drawInfoPanel();
		}


	}


}
