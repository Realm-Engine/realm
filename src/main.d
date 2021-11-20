

import std.stdio;
import glfw3.api;
import realm.game;
int main()
{
	writeln("Hello world");
	RealmGame game = new RealmGame(800,600,"Realm!");

	game.run();
	return 1;
}