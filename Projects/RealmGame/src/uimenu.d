module realm.uimenu;

import realm.engine.ui.realmui;
import realm.engine.core;
import realm.engine.app;
import realm.engine.ecs;
class UIMenu
{

	private RealmUI.UIElement cameraInfo;
	private Camera camera;
	private RealmUI.UIElement mouseInfo;
	private RealmUI.UIElement button;
	mixin RealmEntity!("Menu");
	this(Camera camera)
	{
		this.camera = camera;
		cameraInfo =  RealmUI.createElement(vec3(-950,650,0),vec3(600,50,1),vec3(0,0,0));
		mouseInfo =  RealmUI.createElement(vec3(-950,550,0),vec3(600,50,1),vec3(0,0,0));
		//button = RealmUI.createElement(vec3(0),vec3(200,200,1),vec3(0));
	}

	void update()
	{
		double mouseX = InputManager.getMouseAxis(MouseAxis.X);
		double mouseY = InputManager.getMouseAxis(MouseAxis.Y);

		RealmUI.drawTextString(cameraInfo,vec4(0,0,0,1),vec4(1), RealmUI.TextLayout(4,6,24),"Camera X: %.2f Y: %.2f Z: %.2f",camera.position.x,camera.position.y,camera.position.z);
		RealmUI.drawTextString(mouseInfo,vec4(0,0,0,1),vec4(1), RealmUI.TextLayout(4,6,24),"Mouse X: %.2f Y: %.2f",mouseX,mouseY);
		//RealmUI.button(button,vec4(1),vec4(1,0,0,1),"Press me!",RealmUI.TextLayout(4,6,24));
	}


}
