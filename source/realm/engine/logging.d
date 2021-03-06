module realm.engine.logging;
private
{
	import core.vararg;
	import core.stdc.stdio;
	import std.format;
	import std.stdio;
	import std.meta;
	import std.string;
}

class Logger
{
	
	static void LogWarning(T...)(string fmt, T t)
	{
		writeln("[Warning] " ~ fmt.format(t));
	}

	static void LogInfo(T...)(string fmt, T t)
	{
		writeln("[Log] " ~ fmt.format(t));
	}

	static void LogInfo(T...)(bool cond, string fmt, T t)
	{
		if(cond)
		{
			LogInfo(fmt,t);
		}
	}

	static void LogError(int line = __LINE__,string file = __FILE__,T...)( string fmt,T t )
	{
		writeln("[Error] %s(%d): %s".format(file,line,fmt.format(t)) );
	}

	static void LogError(int line = __LINE__,string file = __FILE__,T...)(bool cond, string fmt,T t )
	{
		if(!cond)
		{
			LogError!(line,file)(fmt.format(t));
		}
	}

	static void Assert(int line = __LINE__,string file = __FILE__,T...)(bool cond,string fmt, T t)
	{
		if(!cond)
		{
			LogError!(line,file)(fmt.format(t));
			assert(cond);
		}

	}

	static void LogWarningUnsafe(string fmt, ...) nothrow
	{
		import core.vararg;
		const char* cStr = toStringz(fmt);
		char[256] formated;
		sprintf(formated.ptr,cStr,_arguments.ptr,_argptr);
		
	}


}

