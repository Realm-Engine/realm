module realm.engine.logging;
private
{
	import core.vararg;
	import core.stdc.stdio;
	import std.format;
	import std.stdio;
	import std.meta;
}

class Logger
{
	
	static void LogWarning(T...)(string fmt, T t)
	{
		writeln("[Warning] %s".format(fmt.format(t)));
	}

	static void LogInfo(T...)(string fmt, T t)
	{
		writeln("[Log] %s".format(fmt.format(t)));
	}

	static void LogError(int line = __LINE__,string file = __FILE__,T...)( string fmt,T t )
	{
		writeln("[Error] %s(%d): %s".format(file,line,fmt.format(t)) );
	}
	
	static void Assert(int line = __LINE__,string file = __FILE__,T...)(bool cond,string fmt, T t)
	{
		if(!cond)
		{
			LogError!(line,file)("%s".format(fmt.format(t)));
			assert(cond);
		}

	}

}

