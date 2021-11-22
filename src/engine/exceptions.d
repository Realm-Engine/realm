module realm.engine.exceptions;
import std.format;

class RendererWorkerException: Exception
{
	this(string msg)
	{
		super(msg);
	}
}

class ShaderCompileError : RendererWorkerException
{
	this(string name,char[] err)
	{
		super("%s failed to compile\nError:%s".format(name,err));
	}
}