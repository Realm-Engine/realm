module realm.fsm.gamestate;

abstract class GameState
{
	abstract void enter();
	abstract void finish();
	abstract void update();


}