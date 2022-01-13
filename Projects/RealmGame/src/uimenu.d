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
	private EntityManager entityManager;
	private vec4 color = vec4(24,24,25,1);
	mixin RealmEntity!("Menu");
	this(Camera camera,EntityManager entityManager)
	{
		this.camera = camera;
		this.entityManager = entityManager;
		cameraInfo =  RealmUI.createElement(vec3(150,680,1),vec3(300,25,1),vec3(0,0,0));
		mouseInfo =  RealmUI.createElement(vec3(150,630,1),vec3(300,25,1),vec3(0,0,0));
		button = RealmUI.createElement(vec3(75,100,1),vec3(150,25,1),vec3(0));
		infoPanel = RealmUI.createElement(vec3(75,200,1),vec3(150,400,1),vec3(0));
		entityName = RealmUI.createElement(vec3(75,350,1),vec3(100,25,1),vec3(0));
	}

	void drawInfoPanel()
	{
		RealmUI.drawPanel(infoPanel,color);
		GameEntity[] gameEntities = entityManager.getEntities!(GameEntity)();
		GameEntity entity = gameEntities[0];
		RealmUI.drawTextString(entityName,vec4(0,0,0,1),color,RealmUI.TextLayout(4,6,16),gameEntities[0].entityName);

		if(RealmUI.button(button,vec4(0,0,0,1),vec4(1),"Press me!",RealmUI.TextLayout(4,6,24)) == RealmUI.ButtonState.PRESSED)
		{
			Logger.LogInfo("Button pressed");
		}
	}

	void update()
	{
		import std.stdio;
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
