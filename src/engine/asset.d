module realm.engine.asset;
public
{
	import dimage;
	import imagefmt;
}

private
{
	import std.string;
	import std.stdio;
	import std.file;
	import std.array;
	import realm.engine.graphics.core;
	import realm.engine.graphics.material;
	import std.algorithm.comparison : equal;
}

IFImage readImageBytes(string path)
{
	IFImage img = read_image(path,4);
	long fmtIndix = lastIndexOf(path,'.');
	string fmt = path[fmtIndix+1..path.length];
	switch(fmt)
	{
		case "png":
			img = read_image(path,4);
			break;
		case "jpg":
			img = read_image(path,3);
			break;
		default:
			writeln("Unsupported image format");
			break;
	}
	return img;
}

Image readImage(string path)
{
	File source = File(path);
	Image texture;
	long fmtIndix = lastIndexOf(path,'.');
	string fmt = path[fmtIndix+1..path.length];
	switch(fmt)
	{
		case "png":
			texture = PNG.load(source);
			break;
		case "tga":
			texture = TGA.load(source);
			break;
		default:
			writeln("Unsupported image format");
			break;
	}
	return texture;
}


ShaderProgram loadShaderProgram(string path,string name)
{

	enum CurrentProcess
	{
		Shared,
		Fragment,
		Vertex,
		None
	}
	ShaderProgram program;
	//string shader = readText(path);
	auto file = File(path);
	auto range = file.byLine();
	string sharedData ="";
	string fragmentData = "";
	string vertexData = "";
	CurrentProcess current = CurrentProcess.None;
	string baseVertex = readText("./src/engine/Assets/Shaders/baseVertex.glsl");
	string baseFragment = readText("./src/engine/Assets/Shaders/baseFragment.glsl");
	string core = readText("./src/engine/Assets/Shaders/core.glsl");
	string vertexName;
	string fragmentName;
	foreach (line; range)
	{
		//writeln(line);
		if(int idx = line.indexOf("#shader") > -1)
		{
			
			char[][] args = line.split(" ");
			
			if(args[1].strip() == "shared")
			{
				current = CurrentProcess.Shared;
				
			}
			else if(args[1].strip() == "vertex")
			{
				current = CurrentProcess.Vertex;
				vertexName = cast(string)args[2].strip();
				
			}
			else if(args[1].strip() == "fragment")
			{
				current = CurrentProcess.Fragment;
				
				fragmentName = cast(string)args[2].strip();
				
			}
			continue;

		}
		string newLine =  ("\n %s".format( line));
		if(current == CurrentProcess.Shared)
		{
			sharedData ~= newLine; 

		}
		else if(current == CurrentProcess.Vertex)
		{
			vertexData ~= newLine;
		}
		else if(current == CurrentProcess.Fragment)
		{
			fragmentData ~= newLine;
		}

	}

	string vertexText = "#version 460 core\n"~sharedData ~"\n" ~baseVertex ~ "\n" ~core ~ vertexData;
	string fragmentText = "#version 460 core\n" ~ sharedData ~"\n" ~baseFragment ~ "\n" ~ core  ~ "\n"  ~ fragmentData;
	Shader vertexShader = new Shader(ShaderType.VERTEX,vertexText,vertexName);
	Shader fragmentShader = new Shader(ShaderType.FRAGMENT,fragmentText,fragmentName);
	program = new ShaderProgram(vertexShader,fragmentShader,name);

	return program;





}
