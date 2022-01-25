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
	private RealmUI.UIElement seedInput;
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
		seedInput = RealmUI.createElement(vec3(0,-60,0),vec3(300,25,1),vec3(0));
		//seedInput = "realm!";
	}

	override void update()
	{
		import std.digest.crc;
		import std.conv;
		import std.bitmanip;
		import std.math;
		RealmUI.drawPanel(mainPanel);
		RealmUI.containerPush(mainPanel);
		RealmUI.drawTextString(text,RealmUI.TextLayout(4,6,30),"Generate world");
		string seedStr = RealmUI.textBox(seedInput,RealmUI.TextLayout(4,6,24));
		if(RealmUI.button(generateButton,"Generate",RealmUI.TextLayout(4,6,24)) == RealmUI.ButtonState.PRESSED)
		{
			auto crc = new CRC32Digest();
			ubyte[] hash = crc.digest(seedStr);
			int seed = abs(hash.read!(int)());
			Logger.LogInfo("World seed: %d", seed);
			manager.getEntities!(StateMachine)()[0].changeState(new MainState(manager,seed));
		}
		RealmUI.containerPop();
	}
	override void finish()
	{

	}

}
