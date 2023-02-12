module realm.engine.terminal;

public
{
	import realm.engine.terminal.core;
}

version(Windows)
{
	
	private import realm.engine.terminal.winterm;
	ITerminal terminal;
	static this()
	{
		terminal = new WindowsTerminal();
	}
}

