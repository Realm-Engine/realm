
version(RealmDynamicLibrary)
{
	import core.sys.windows.windows;
	import core.sys.windows.dll;
	import core.runtime;
	import realm.game;
	import std.stdio;
	import realm.engine.logging;
	mixin SimpleDllMain;
	pragma(msg,"Building project to dynamic library");
	
	void realm_main()
	{
		writeln("rti start");
		RealmGame game = new RealmGame(1280,720,"Realm!");

		game.run();
		scope(exit)
		{
			game.destroy();
		}
	}
}
version(RealmExecutable)
{
	pragma(msg,"Building project to executable");
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
}

version(RealmHotReload)
{
	import std.stdio;

	import core.sys.windows.windows;
	import core.runtime;
	void main()
	{
		HMODULE h = cast(HMODULE)Runtime.loadLibrary("realmgame.dll");
		FARPROC fp = GetProcAddress(h,"realm_main");
		auto fun = cast(void function()) fp;
		
		fun();
	}
}