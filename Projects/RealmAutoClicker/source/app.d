module game.app;
import std.stdio;
import realm.engine.graphics.core;
import realm.engine.graphics.renderer;
import realm.engine.app;
import realm.engine.ui.realmui;
import gl3n.linalg;
import realm.engine.ecs;
import realm.engine.logging;
import game.cards;
import realm.engine.asset;
import std.random;
import std.range;
__gshared GameEntityManager gameEntityManager;
__gshared CardManager cardManager;




class RealmGame : RealmApp
{

	


	Player player;
	InfoBar infoBar;
	IFImage houseImage;
	HouseCard card;

	this(int width, int height, const char* title, string[] args)
	{
		super(width,height,title,args);
		Renderer.get();
		
		VirtualFS.registerPath!("Projects/RealmAutoClicker/Assets")("Assets");
		cardManager = new CardManager;
	}

	override void start()
	{
		
		houseImage = readImageBytes("$Assets/Images/house.png");
		RealmUI.themePush(RealmUI.UITheme(vec4(1),vec4(0,0,0,1)));
		auto windowSize = getWindowSize();

		player = gameEntityManager.instantiate!(Player);
		infoBar = gameEntityManager.instantiate!(InfoBar)(windowSize[0],windowSize[1]);
		cardManager.instantiateCard!(HouseCard)(houseImage,vec3(0));
		cardManager.instantiateCard!(HouseCard)(houseImage,vec3(0));
		cardManager.instantiateCard!(HouseCard)(houseImage,vec3(0));

	}



	override void update()
	{

		double drawTime = Renderer.get.getMetrics().frameTime;
		gameEntityManager.updateEntities(drawTime/100);
		cardManager.update(drawTime/100);
		Renderer.get.update();
		
	}
	

}

class Player
{
	mixin RealmEntity!("Player",TimerComponent);
	ulong coins;
	ulong tickSpeed;
	TimerComponent timer;
	
	void start()
	{
		tickSpeed = 500;
		timer = getComponent!(TimerComponent)();
		timer.durration = tickSpeed;
		timer.timerTickCallback = &timerTick;
	}
	void update(float dt)
	{
		
		updateComponents();
		
	}

	void timerTick()
	{
		auto result = dice(16.repeat(6));
		Logger.LogInfo("Roll: %d",result);
		static foreach(Type; cardManager.EntityTypes)
		{
			foreach(card; cardManager.getEntities!(Type)())
			{
				if(card.getLuckyNumber() == result)
				{
					coins += card.getReward();
					Logger.LogInfo("Won %d from %s",card.getReward(),card.entityName);
				}
			}
		}
	}

}

class InfoBar
{
	mixin RealmEntity!("InfoBar");
	RealmUI.UIElement panel;
	RealmUI.UIElement playerCoins;
	RealmUI.UIElement tickSpeed;
	void start(int windowWidth, int windowHeight)
	{
		panel = RealmUI.createElement(vec3(windowWidth/2,windowHeight-10,0),vec3(windowWidth,50,1),vec3(0));
		playerCoins = RealmUI.createElement(vec3((-windowWidth/2) + 200,-12.5,0),vec3(200,25,1),vec3(0));
		playerCoins.textLayout = RealmUI.TextLayout(4,6,12);
		tickSpeed = RealmUI.createElement(vec3((-windowWidth/2) + 400,-12.5,0),vec3(200,25,1),vec3(0));
	}

	void update(float dt)
	{
		Player player = gameEntityManager.getEntities!(Player)[0];

		RealmUI.drawPanel(panel);
		RealmUI.containerPush(panel);
		RealmUI.drawTextString(playerCoins,"Coins: %d", player.coins);
		RealmUI.drawTextString(tickSpeed,"Tick speed: %fs",player.tickSpeed/1000);
		RealmUI.containerPop();
	}
}


class TimerComponent
{
	long durration;
	import std.datetime.stopwatch;
	private StopWatch stopWatch;
	
	void delegate() timerTickCallback;

	void componentStart(E)(E parent)
	{
		
		stopWatch = StopWatch(AutoStart.yes);
	}

	void componentUpdate(E)(E parent)
	{
		long elapsedMsecs = stopWatch.peek.total!"msecs";
		if(elapsedMsecs >= durration)
		{
			
			stopWatch.reset();
			if(timerTickCallback)
			{
				timerTickCallback();
			}
		}

	}
}

class GameEntityManager
{
	
	mixin EntityRegistry!(Player,InfoBar);
}

void main(string[] args)
{
	RealmGame game = new RealmGame(1600,900,"Auto Clicker!",args);
	game.run();
	scope(exit)
	{
		game.destroy();
	}
}


static this()
{
	gameEntityManager = new GameEntityManager;
	
}