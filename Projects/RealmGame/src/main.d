
version(RealmDynamicLibrary)
{
	import core.sys.windows.windows;
	import core.sys.windows.dll;
	import core.runtime;
	import realm.game;
	import std.stdio;
	import realm.engine.logging;
	pragma(msg,"Building project to dynamic library");

	version(Windows)
	{
		export extern(C) void realm_main()
		{
			writeln("rti start");
			RealmGame game = new RealmGame(1280,720,"Realm!");

			game.run();
			scope(exit)
			{
				game.destroy();
			}
		}

		extern(Windows) bool DllMain(void* hInstance, uint ulReason, void*)
		{
			switch(ulReason)
			{
				case DLL_PROCESS_ATTACH:
					dll_process_attach(hInstance,true);
					break;
				case DLL_PROCESS_DETACH:
					dll_process_detach(hInstance,true);
					break;
				case DLL_THREAD_ATTACH:
					dll_thread_attach(true,true);
					break;
				case DLL_THREAD_DETACH:
					dll_thread_detach(true,true);
					break;
				default:
					assert(0);
			}
			return true;
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

