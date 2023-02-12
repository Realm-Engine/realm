module realm.engine.terminal.winterm;

 
private
{
	import core.sys.windows.windows;
	extern (Windows) bool SetConsoleTextAttribute(void*, ushort) nothrow @nogc;
	extern (Windows) void* GetStdHandle(uint) nothrow @nogc;
	import realm.engine.terminal.core;
	import core.stdc.stdio;
}


class WindowsTerminal : ITerminal
{
	private void* handle;
	this()
	{
		handle = GetStdHandle(STD_OUTPUT_HANDLE);
	}
	

	void write(const char* string)
	{
		
		printf(string);
		
	}
	void write(const char* str, ...) nothrow @nogc
	{
		
		vprintf(str,_argptr);
		
	}

	void setColor(TerminalColor color) nothrow @nogc
	{
		
		SetConsoleTextAttribute(handle,color);
	}

}