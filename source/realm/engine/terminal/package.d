module realm.engine.terminal;

public
{
	import realm.engine.terminal.core;

	ITerminal terminal;
}

version(Windows)
{
	
	private import realm.engine.terminal.winterm;
	
	static this()
	{
		terminal = new WindowsTerminal();
	}
}

