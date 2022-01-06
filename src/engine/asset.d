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
	import realm.engine.graphics.core : Shader,ShaderProgram, ShaderType;
	import realm.engine.graphics.material;
	import std.algorithm.comparison : equal;
	import realm.engine.logging;
	import realm.engine.core : Mesh;
	import std.conv;
	import std.range;
	import std.algorithm;
	
}

static this()
{
	if(!exists("Cache"))
	{
		Logger.LogInfo("Creating cache folder");
		mkdir("Cache");
	}
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



private Mesh loadObj(string path)
{
	import gl3n.linalg;
	auto file = File(path);
	Mesh result;
	vec3[] vertices;
	vec3[] normals;
	vec2[] texCoords;
	
	foreach(index,line ; enumerate(file.byLine,0))
	{
		char[][] values = line.strip().split(" ").map!(s => s.strip()).array;
		if(values.length <= 0)
		{
			continue;
		}
		switch(values[0])
		{
			case "v":
				auto vals = values.drop(1).map!(s => parse!float(s)).takeExactly(3);
				vec3 vertex;
				vertex.vector = vals.array;
				vertices ~= vertex;
				
				break;
			case "vn" :
				auto vals = values.drop(1).map!(s => parse!float(s)).takeExactly(3);
				vec3 normal;
				normal.vector = vals.array;
				normals ~= normal;
				break;
			case "vt":
				auto vals = values.drop(1).map!(s => parse!float(s)).takeExactly(2);
				vec2 texCoord;
				texCoord.vector = vals.array;
				texCoords ~= texCoord;
				break;
			case "f" :
				uint faceBase = cast(uint)result.positions.length;
				foreach(face ; values.drop(1))
				{
					if(face == "")
					{
						break;
					}
					string token = "/";
					bool hasTexCoord = true;
					if(line.indexOf("//") >= 0)
					{
						hasTexCoord = false;
						token = "//";
					}
					auto indices = face.split(token).map!(s => parse!uint(s));
					uint vIdx = indices[0];
					uint vnIdx;
					uint vtIdx;
					if(!hasTexCoord)
					{
						vnIdx = indices[1];
					}
					else
					{
						vnIdx = indices[2];
						vtIdx = indices[1];
					}
					 
					result.positions ~= vertices[vIdx - 1 ];
					result.normals ~= normals[vnIdx - 1];
					if(!hasTexCoord)
					{
						result.textureCoordinates ~= vec2(1,1);
					}
					else
					{
						result.textureCoordinates ~= texCoords[vtIdx - 1];
					}
					
					
				}
				ulong numFaces = values.drop(1).array.length;
				int start = 0;
				if(result.faces.length > 0)
				{
					start = result.faces.maxElement() + 1;
				}
				//cast(int)result.faces.length;
				int end = start + cast(int)numFaces;
				auto tris = iota(start, end).slide!(Yes.withPartial)(3,3);
				
				foreach(t ; tris)
				{
					
					uint[] triangle;
					foreach(i; t)
					{
						triangle ~= cast(uint)i;
					}
					int missingFaces = 3 - cast(int)triangle.length;
					if(missingFaces > 0)
					{
						for(int i = 0; i < missingFaces; i++)
						{
							triangle ~= ((3 + i) % 3) + ((end-4) + i) ;
						}
					}
					else if(missingFaces < 0)
					{
						Logger.LogError("Bad face");
					}
					
					result.faces ~= triangle;
				}
				
				

				break;

			default:
				break;
		}
	}
	
	
	result.calculateTangents();
	return result;
}

Mesh loadMesh(string path)
{
	
	long fmtIndix = lastIndexOf(path,'.');
	string fmt = path[fmtIndix+1..path.length];
	Mesh result;
	switch(fmt)
	{
		case "obj":
			result = loadObj(path);
			break;
		default:
			Logger.LogError("%s unknown file extension",fmt);
			break;
	}
	return result;


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
	if(!exists(path))
	{
		Logger.LogError("Could not find path: %s", path);
		return program;
	}
	auto file = File(path);
	auto range = file.byLine();

	CurrentProcess current = CurrentProcess.None;
	string baseVertex = readText("./src/engine/Assets/Shaders/baseVertex.glsl");
	string baseFragment = readText("./src/engine/Assets/Shaders/baseFragment.glsl");
	string core = readText("./src/engine/Assets/Shaders/core.glsl");

	string sharedData ="";
	string fragmentData = "";
	string vertexData = "";
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

				
			}
			else if(args[1].strip() == "fragment")
			{
				current = CurrentProcess.Fragment;
				

				
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

	Shader vertexShader = new Shader(ShaderType.VERTEX,vertexText, name ~ " Vertex");
	Shader fragmentShader = new Shader(ShaderType.FRAGMENT,fragmentText,name ~ " Fragment");
	program = new ShaderProgram(vertexShader,fragmentShader,name);

	return program;





}
