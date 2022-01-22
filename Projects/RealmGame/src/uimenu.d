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
	private EntityManager entityManager;
	private int currentEntity;
	private vec4 color = vec4(24,24,25,1);
	mixin RealmEntity!("Menu");
	void start(Camera camera,EntityManager entityManager)
	{
		currentEntity = 0;
		this.camera = camera;
		this.entityManager = entityManager;
		cameraInfo =  RealmUI.createElement(vec3(150,680,1),vec3(300,25,1),vec3(0,0,0));
		mouseInfo =  RealmUI.createElement(vec3(150,630,1),vec3(300,25,1),vec3(0,0,0));
		button = RealmUI.createElement(vec3(0,-100,0),vec3(150,25,1),vec3(0));
		infoPanel = RealmUI.createElement(vec3(75,200,1),vec3(150,400,1),vec3(0));
		entityName = RealmUI.createElement(vec3(0,150,0),vec3(100,35,1),vec3(0));

		nextEntity = RealmUI.createElement(vec3(50,100,0),vec3(50,25,1),vec3(0));
		lastEntity = RealmUI.createElement(vec3(-50,100,0),vec3(50,25,1),vec3(0));
		toggleActive = RealmUI.createElement(vec3(0,50,0),vec3(100,25,1),vec3(0));
		generateMapButton = RealmUI.createElement(vec3(600,50,0),vec3(100,50,1),vec3(0));

	}

	void drawInfoPanel()
	{

		RealmUI.drawPanel(infoPanel,color);
		RealmUI.containerPush(infoPanel);
		GameEntity[] gameEntities = entityManager.getEntities!(GameEntity)();
		World gameWorld = entityManager.getEntities!(World)()[0];

		if(RealmUI.button(button,vec4(0,0,0,1),vec4(1),"Press me!",RealmUI.TextLayout(4,6,24)) == RealmUI.ButtonState.PRESSED)
		{
			Logger.LogInfo("Button pressed");
		}
		if(RealmUI.button(nextEntity,vec4(0,0,0,1),vec4(1),"Next",RealmUI.TextLayout(4,6,16)) == RealmUI.ButtonState.PRESSED )
		{
			if(currentEntity < gameEntities.length-1)
			{
				currentEntity++;
			}
		}
		if(RealmUI.button(lastEntity,vec4(0,0,0,1),vec4(1),"Prev",RealmUI.TextLayout(4,6,16)) == RealmUI.ButtonState.PRESSED )
		{
			if(currentEntity > 0)
			{
				currentEntity--;
			}
		}
		GameEntity entity = gameEntities[currentEntity];
		if(RealmUI.button(toggleActive,vec4(0,0,0,1),vec4(1),"Toggle",RealmUI.TextLayout(4,6,16)) == RealmUI.ButtonState.PRESSED)
		{
			entity.active = entity.active ^ true;
		}
		RealmUI.drawTextString(entityName,vec4(0,0,0,1),color,RealmUI.TextLayout(4,6,16),entity.entityName);
		RealmUI.containerPop();
		if(RealmUI.button(generateMapButton,vec4(0,0,0,1),color,"Generate",RealmUI.TextLayout(4,6,16)) == RealmUI.ButtonState.PRESSED)
		{
			gameWorld.generateWorld();
		}
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

			RealmUI.drawTextString(cameraInfo,vec4(0,0,0,1),color, RealmUI.TextLayout(4,6,24),"Camera X: %.2f Y: %.2f Z: %.2f",camera.position.x,camera.position.y,camera.position.z);
			RealmUI.drawTextString(mouseInfo,vec4(0,0,0,1),color, RealmUI.TextLayout(4,6,24),"Mouse X: %.2f Y: %.2f",mouseX,mouseY);
			drawInfoPanel();
		}


	}


}
