module game.cards;
import realm.engine.ecs;	
private
{
	import realm.engine.asset;
	import realm.engine.graphics.core;
	import realm.engine.ui.realmui;
	import realm.engine.core;
	import realm.engine.app;
}
__gshared IFImage cardBackdrop;

class CardManager
{
	RealmUI.UIElement cardPanel;
	RealmUI.UITheme cardTheme;
	mixin EntityRegistry!(HouseCard);
	this()
	{
		auto windowSize = RealmApp.getWindowSize();
		cardBackdrop = readImageBytes("$Assets/Images/card-backdrop.png");
		cardTheme = RealmUI.UITheme(vec4(1.0),vec4(0,0,0,1));
		cardPanel = RealmUI.createElement(vec3(windowSize[0]/2,windowSize[1]-200,0),vec3(windowSize[0],300,1),vec3(0));
	}

	void update(float dt)
	{
		RealmUI.drawPanel(cardPanel);
		RealmUI.containerPush(cardPanel);
		RealmUI.themePush(cardTheme);
		updateEntities(dt);
		RealmUI.themePop();
		RealmUI.containerPop();
	}
	
}

mixin template Card(alias string CardName,int LuckyNumber,int Reward)
{
	

	mixin RealmEntity!(CardName,Transform);
	
	private RealmUI.UIElement cardPanel;
	private RealmUI.UIElement cardImage;
	private RealmUI.UIElement cardLabel;
	private RealmUI.UIElement cardInfo;
	private RealmUI.UIElement luckyNumberLabel;
	private RealmUI.UIElement rewardLabel;
	private Texture2D cardTexture;
	private Texture2D cardBackdropTexture;
	private Transform transform;
	
	

	void start(ref IFImage image,vec3 position)
	{
		transform = getComponent!(Transform)();
		cardTexture = new Texture2D(&image);
		cardBackdropTexture = new Texture2D(&cardBackdrop);
		TextureDesc desc = TextureDesc(ImageFormat.SRGBA8,TextureFilterfunc.LINEAR,TextureWrapFunc.CLAMP_TO_BORDER);
		transform = new Transform(position,vec3(0),vec3(200,300,1));
		cardPanel = RealmUI.createElement(transform,cardBackdropTexture,desc);
		cardImage = RealmUI.createElement(vec3(0,25,0),vec3(200,200,1),vec3(0),cardTexture,desc);
		cardLabel = RealmUI.createElement(vec3(0,125,0),vec3(200,25,1),vec3(0)); 
		cardInfo = RealmUI.createElement(vec3(0,-112.5,0),vec3(200,75,1),vec3(0));
		luckyNumberLabel = RealmUI.createElement(vec3(-80,25,0),vec3(30,15,1),vec3(0));
		rewardLabel = RealmUI.createElement(vec3(80,25,0),vec3(30,15,1),vec3(0));

	}

	void drawCard()
	{
		RealmUI.drawPanel(cardPanel);
		RealmUI.containerPush(cardPanel);
		RealmUI.drawPanel(cardImage);
		RealmUI.drawTextString(cardLabel,CardName);
		RealmUI.drawPanel(cardInfo);
		RealmUI.containerPush(cardInfo);
		RealmUI.drawTextString(luckyNumberLabel,"%d",LuckyNumber);
		RealmUI.drawTextString(rewardLabel,"%d",Reward);
		RealmUI.containerPop();
		RealmUI.containerPop();
	}

	void update(float dt)
	{
		drawCard();
	}
	
	int getLuckyNumber()
	{
		return LuckyNumber;
	}
	int getReward()
	{
		return Reward;
	}

}

class HouseCard
{
	mixin Card!("House",3,1);


}