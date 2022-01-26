module realm.worldgenmenu;
import realm.entitymanager;
import realm.fsm.gamestate;
import realm.engine.ui.realmui;
import gl3n.linalg;
import realm.engine.app;
import realm.engine.input;
import realm.engine.logging;
import realm.mainstate;


class WorldGenMenu : GameState
{


	private EntityManager manager;
	private RealmUI.UIElement mainPanel;
	private RealmUI.UIElement generateButton;
	private RealmUI.UIElement nameInput;
	private RealmUI.UIElement worldNameInput;
	private RealmUI.UIElement text;
	this(EntityManager manager)
	{
		this.manager = manager;
	}
	override  void enter() {
		auto windowSize = RealmApp.getWindowSize();
		mainPanel = RealmUI.createElement(vec3(windowSize[0] / 2,windowSize[1]/2, 0),vec3(windowSize[0],windowSize[1],1),vec3(0));
		text = RealmUI.createElement(vec3(0,100,0),vec3(600,100,1),vec3(0));
		generateButton = RealmUI.createElement(vec3(0,-120,0),vec3(300,25,1),vec3(0));
		worldNameInput = RealmUI.createElement(vec3(0,-60,0),vec3(300,25,1),vec3(0));
		text.textLayout = RealmUI.TextLayout(4,6,30);
		nameInput.textLayout = RealmUI.TextLayout(4,6,24);
		generateButton.textLayout = RealmUI.TextLayout(4,6,24);
		//seedInput = "realm!";
	}

	override void update()
	{
		RealmUI.drawPanel(mainPanel);
		RealmUI.containerPush(mainPanel);
		RealmUI.drawTextString(text,"Generate world");
		string name = RealmUI.textBox(worldNameInput);
		if(RealmUI.button(generateButton,"Generate") == RealmUI.ButtonState.PRESSED)
		{
			Logger.LogInfo("Generating world: %s", name);
			manager.getEntities!(StateMachine)()[0].changeState(new MainState(manager));
		}
		RealmUI.containerPop();
	}
	override void finish()
	{

	}

}
