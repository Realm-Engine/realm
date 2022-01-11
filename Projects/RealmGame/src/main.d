

import std.stdio;
import glfw3.api;
import realm.game;
int main()
{

	RealmGame game = new RealmGame(1280,720,"Realm!");

	game.run();
	scope(exit)
	{
		game.destroy();
	}
	return 1;
}