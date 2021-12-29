

import std.stdio;
import glfw3.api;
import realm.game;
int main()
{

	RealmGame game = new RealmGame(800,600,"Realm!");

	game.run();
	scope(exit)
	{
		game.destroy();
	}
	return 1;
}