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

enum LogLevel {INFO,WARN,ERROR}

template log(LogLevel level)
{
	import core.vararg;
	void log(string fn = __FUNCTION__,string file=__FILE__,size_t line = __LINE__)(string fmt,...) nothrow @nogc
	{
		TypeInfo[] arguments = _arguments;
		char[256] formatted;
		//alias prefix = "[" ~ level.stringof  ~"] " ~ file ~ ":" ~ line ~ ":" ~fn ~" ";
		sprintf(formatted.ptr,cast (const (char*))fmt,_argptr);
		printf(cast(const (char*))("[" ~ level.stringof  ~"] " ~ file ~ ":" ~ line ~ ":" ~fn ~" %s\n"),formatted.ptr);
		
		
	}
}
alias info = log!(LogLevel.INFO);
alias warning = log!(LogLevel.WARN);
alias error = log!(LogLevel.ERROR);
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

	
	


	


}

