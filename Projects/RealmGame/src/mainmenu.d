module realm.mainmenu;


import realm.entitymanager;
import realm.fsm.gamestate;
import realm.engine.ui.realmui;
import gl3n.linalg;
import realm.engine.app;
import realm.engine.input;
import realm.engine.logging;
import realm.mainstate;
import realm.worldgenmenu;
class MainMenu : GameState
{
	private RealmUI.UIElement mainPanel;
	private RealmUI.UIElement startButton;
	private RealmUI.UIElement text;
	private EntityManager manager;
	this(EntityManager manager)
	{
		this.manager = manager;
	}

	override void enter()
	{
		auto windowSize = RealmApp.getWindowSize();
		mainPanel = RealmUI.createElement(vec3(windowSize[0] / 2,windowSize[1]/2, 0),vec3(windowSize[0],windowSize[1],1),vec3(0));
		text = RealmUI.createElement(vec3(0,100,0),vec3(225,100,1),vec3(0));
		startButton = RealmUI.createElement(vec3(0,-60,0),vec3(125,50,1),vec3(0));
		text.textLayout = RealmUI.TextLayout(4,6,40);
		startButton.textLayout = RealmUI.TextLayout(4,6,24);
		
	}

	override void finish() {
		
	}


	override void update()
	{
		
		RealmUI.drawPanel(mainPanel);
		RealmUI.containerPush(mainPanel);
		RealmUI.drawTextString(text,"Realm!");
		if(RealmUI.button(startButton,"Start") == RealmUI.ButtonState.PRESSED)
		{
			manager.getEntities!(StateMachine)()[0].changeState(new WorldGenMenu(manager));
		}
		RealmUI.containerPop();
		
	}

	~this()
	{
		RealmUI.deleteElement(mainPanel);
		RealmUI.deleteElement(startButton);
		RealmUI.deleteElement(text);
	}

}