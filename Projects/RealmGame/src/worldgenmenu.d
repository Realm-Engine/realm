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
	private RealmUI.UIElement genSettingsPanel;
	private RealmUI.UIElement oceanLevelInput;
	private RealmUI.UIElement worldHeightInput;
	private RealmUI.UIElement height;
	private RealmUI.UIElement generateButton;
	private RealmUI.UIElement nameInput;
	private RealmUI.UIElement worldNameInput;
	private RealmUI.UIElement text;
	private RealmUI.UIElement oceanLevelLabel;
	private RealmUI.UIElement worldHeightLabel;
	
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
		genSettingsPanel = RealmUI.createElement(vec3((-windowSize[0] / 2) + 200,0,0),vec3(400,windowSize[1],1),vec3(0));
		oceanLevelInput = RealmUI.createElement(vec3(0,200,0),vec3(200,25,1),vec3(0));
		worldHeightInput = RealmUI.createElement(vec3(0,100,0),vec3(200,25,1),vec3(0));
		oceanLevelLabel = RealmUI.createElement(vec3(0,250,0),vec3(200,25,1),vec3(0));
		worldHeightLabel = RealmUI.createElement(vec3(0,150,0),vec3(200,25,1),vec3(0));
		//seedInput = "realm!";
	}

	void genSettings()
	{
		import std.conv;
		RealmUI.themePush(RealmUI.UITheme(vec4(111,24,43,1),vec4(1)));
		RealmUI.drawPanel(genSettingsPanel);
		RealmUI.containerPush(genSettingsPanel);
		string oceanLevelStr = RealmUI.textBox(oceanLevelInput);
		string worldHeightStr = RealmUI.textBox(worldHeightInput);
		RealmUI.drawTextString(oceanLevelLabel,"Ocean level:");
		RealmUI.drawTextString(worldHeightLabel,"World height strength:");
		RealmUI.themePop();
		RealmUI.containerPop();
		string name = RealmUI.textBox(worldNameInput);
		if(RealmUI.button(generateButton,"Generate") == RealmUI.ButtonState.PRESSED)
		{
			Logger.LogInfo("Generating world: %s", name);
			float oceanLevel = parse!float(oceanLevelStr);
			float worldHeight = parse!float(worldHeightStr);
			TerrainGeneration generator = manager.instantiate!(TerrainGeneration)(TerrainGeneration.GenSettings(oceanLevel,worldHeight));
			generator.generateMap();
			manager.getEntities!(StateMachine)()[0].changeState(new MainState(manager));
		}
		


	}


	override void update()
	{
		
		RealmUI.drawPanel(mainPanel);
		RealmUI.containerPush(mainPanel);
		
		genSettings();
		RealmUI.containerPop();
	}
	override void finish()
	{

	}

}
