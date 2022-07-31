import std.stdio;
import realmofthedead.game;
void main(string[] args)
{
	RealmGame game = new RealmGame(1600,900,"Realm of the Dead!",args);
	game.run();
	scope(exit)
	{
		game.destroy();
	}

}
