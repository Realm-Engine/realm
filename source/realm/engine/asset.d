module realm.engine.asset;
public
{
    import imagefmt;
}

private
{
    import std.string;
    import std.stdio;
    import std.file;
    import std.array;
    import realm.engine.graphics.core : Shader, StandardShaderModel, ShaderType, ShaderParameter;
    import std.algorithm.comparison : equal;
    import realm.engine.logging;
    import realm.engine.core : Mesh;
    import std.conv;
    import std.range;
    import std.algorithm;
    import std.path;

}

static class VirtualFS
{
    import std.digest.md;

    private static string[string] registeredPaths;

    static string registerPath(string sysPath)(string prefix)
    in
    {

        pragma(msg, "Registering virtual path at: " ~ sysPath);
        static assert(isValidPath(sysPath));
        assert(!prefix.empty);
    }
    out (r)
    {
        assert(isValidPath(r), "Generated path not valid: " ~ r);
        assert(exists(r), "Generated path does not exsist: " ~ r);
        assert(isDir(r), "Generated path is not a directory: " ~ r);
    }
    do
    {
        string path = getcwd() ~ "\\" ~ sysPath;
        Logger.LogInfo("Registering virtual path %s at %s", prefix, path);
        registeredPaths[prefix] = path;
        
        return path;

    }

    static string getSystemPath(string virtualPath)
    {
        scope (failure)
        {
            Logger.LogError("Could not find virtual path: %s", virtualPath);
        }
        long prefixStart = virtualPath.indexOf('$');
        long prefixEnd = virtualPath.indexOf('\\');
        if (prefixEnd <= 0)
        {
            prefixEnd = virtualPath.indexOf('/');
        }
        string prefix = virtualPath[prefixStart + 1 .. prefixEnd];
        string postfix = virtualPath[prefixEnd .. $];
        string sysPath = registeredPaths[prefix] ~ postfix;
        return sysPath;
    }

    static string getVirtualPath(string systemPath)
	{
       
        string prefix;
        string sysDir;
        foreach(kvp; registeredPaths.byKeyValue())
		{
            auto key = kvp.key;
            auto value = kvp.value;
		    if(systemPath.indexOf(value) > -1)
		    {
                sysDir = value;
		        prefix = key; 
		    }
		}
        string virtualPath = '$'~ prefix ~ "\\" ~systemPath[sysDir.length + 1..$];
        
        return virtualPath;
        
	}

    static string getFileName(string virtualPath)
	{
	    long nameStart = virtualPath.lastIndexOf('\\');
        if(nameStart <= 0)
		{
		    nameStart = virtualPath.lastIndexOf('/');
		}
        long nameEnd = virtualPath.indexOf('.');

        return virtualPath[nameStart + 1..nameEnd];

	}

    static void clearCache()
    {

        if (exists("Cache"))
        {
            Logger.LogInfo("Clearing cache");
            auto dir = dirEntries("Cache", "*.bin", SpanMode.depth);
            foreach (entry; dir)
            {
                Logger.LogInfo("Deleting: %s", entry);
                remove(entry);
            }
        }
    }

}

static class ShaderLibrary
{
    private static StandardShaderModel[string] library;

    static bool hasShader(string name)
    {
        return (name in library) !is null;
    }

    static StandardShaderModel getShader(string virtualPath)
    {
        string name = VirtualFS.getFileName(virtualPath);
        if (hasShader(name))
        {
            return library[name];
        }
        return null;
    }

    static void loadDir(string virtualPath)
    {
        string path = VirtualFS.getSystemPath(virtualPath);
        auto dir = dirEntries(path, "*.shader", SpanMode.depth);
        foreach (entry; dir)
        {
            Logger.LogInfo("Loading shader %s into Shader Library", entry);
            library[VirtualFS.getFileName(entry)] = loadShaderProgram(VirtualFS.getVirtualPath(entry));
        }
    }

}

static this()
{
    if (!exists("Cache"))
    {
        Logger.LogInfo("Creating cache folder");
        mkdir("Cache");
    }
    VirtualFS.registerPath!("Assets")("EngineAssets");
    
}

IFImage readImageBytes(string path)
{
    string sysPath = VirtualFS.getSystemPath(path);
    IFImage img;
    long fmtIndix = lastIndexOf(sysPath, '.');
    string fmt = sysPath[fmtIndix + 1 .. sysPath.length];
    switch (fmt)
    {
    case "png":
        img = read_image(sysPath, 4);
        break;
    case "jpg":
        img = read_image(sysPath, 3);
        break;
    default:
        writeln("Unsupported image format");
        break;
    }
    return img;
}

void writeImageBytes(IFImage* image, string path)
{
    string sysPath = VirtualFS.getSystemPath(path);
    IFImage img = read_image(sysPath, 4);
    long fmtIndix = lastIndexOf(sysPath, '.');
    string fmt = sysPath[fmtIndix + 1 .. sysPath.length];
    switch (fmt)
    {
    case "png":
        ubyte result = write_image(sysPath, image.w, image.h, image.buf8, 4);
        Logger.LogError(result == 0, "Could not write image: %s", path);
        break;
    default:
        Logger.LogError("File type not supported: %s", fmt);
        break;

    }

}

private Mesh loadLDraw(string path)
{
    import gl3n.linalg;

    auto file = File(path);
    Mesh result;
    vec3[] vertices;
    vec3[] normals;
    vec2[] texCoords;

    foreach (index, line; enumerate(file.byLine, 0))
    {
        char[][] values = line.strip().split(" ").map!(s => s.strip()).array;
        if (values.length <= 0)
        {
            continue;
        }
        switch (values[0])
        {
        case "3":
            auto color = values[1];
            vec3 v1, v2, v3;
            v1.vector = values[2 .. 5].map!(s => parse!(float)(s)).takeExactly(3).array;
            v2.vector = values[5 .. 8].map!(s => parse!(float)(s)).takeExactly(3).array;
            v3.vector = values[8 .. 11].map!(s => parse!(float)(s)).takeExactly(3).array;
            vertices ~= [v1, v2, v3];
            vec3 side1 = v2 - v1;
            vec3 side2 = v3 - v1;
            vec3 normal = v3.cross(v2);
            normals ~= [normal, normal, normal];
            vec2 uv = vec2(0, 0);
            texCoords ~= [uv, uv, uv];
            break;
        default:
            Logger.LogWarning("Unsupported line type: %s", values[0]);
            break;

        }

    }
    return result;

}

private Mesh loadObj(string path)
{
    import gl3n.linalg;

    auto file = File(path);
    Mesh result;
    vec3[] vertices;
    vec3[] normals;
    vec2[] texCoords;
    Logger.LogInfo("Loading model: %s", path);
    foreach (index, line; enumerate(file.byLine, 0))
    {
        char[][] values = line.strip().split(" ").map!(s => s.strip()).array;
        if (values.length <= 0)
        {
            continue;
        }
        switch (values[0])
        {
        case "v":
            auto vals = values.drop(1).map!(s => parse!float(s)).takeExactly(3);
            vec3 vertex;
            vertex.vector = vals.array;
            vertices ~= vertex;

            break;
        case "vn":
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
        case "f":
            uint faceBase = cast(uint) result.positions.length;
            foreach (face; values.drop(1))
            {
                if (face == "")
                {
                    break;
                }
                string token = "/";
                bool hasTexCoord = true;
                if (line.indexOf("//") >= 0)
                {
                    hasTexCoord = false;
                    token = "//";
                }
                auto indices = face.split(token).map!(s => parse!uint(s));
                uint vIdx = indices[0];
                uint vnIdx;
                uint vtIdx;
                if (!hasTexCoord)
                {
                    vnIdx = indices[1];
                }
                else
                {
                    vnIdx = indices[2];
                    vtIdx = indices[1];
                }

                result.positions ~= vertices[vIdx - 1];
                result.normals ~= normals[vnIdx - 1];
                if (!hasTexCoord)
                {
                    result.textureCoordinates ~= vec2(1, 1);
                }
                else
                {
                    result.textureCoordinates ~= texCoords[vtIdx - 1];
                }

            }
            ulong numFaces = values.drop(1).array.length;
            int start = 0;
            if (result.faces.length > 0)
            {
                start = result.faces.maxElement() + 1;
            }
            //cast(int)result.faces.length;
            int end = start + cast(int) numFaces;
            auto tris = iota(start, end).slide!(Yes.withPartial)(3, 3);

            foreach (t; tris)
            {

                uint[] triangle;
                foreach (i; t)
                {
                    triangle ~= cast(uint) i;
                }
                int missingFaces = 3 - cast(int) triangle.length;
                if (missingFaces > 0)
                {
                    for (int i = 0; i < missingFaces; i++)
                    {
                        triangle ~= ((3 + i) % 3) + ((end - 4) + i);
                    }
                }
                else if (missingFaces < 0)
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
    string sysPath = VirtualFS.getSystemPath(path);
    long fmtIndix = lastIndexOf(sysPath, '.');
    string fmt = sysPath[fmtIndix + 1 .. sysPath.length];
    Mesh result;
    switch (fmt)
    {
    case "obj":
        result = loadObj(sysPath);
        break;
    default:
        Logger.LogError("%s unknown file extension", fmt);
        break;
    }
    result.calculateWorldBoundingBox();
    return result;

}

private string getShaderDefines(ShaderType type, StandardShaderModel shader)
{
    string defines;
    int maxTextureUnits;
    if (type == ShaderType.VERTEX)
    {
        maxTextureUnits = shader.getParameter!(int)(ShaderParameter.MAX_VERTEX_TEXTURE_UNITS);
    }
    else if (type == ShaderType.FRAGMENT)
    {
        maxTextureUnits = shader.getParameter!(int)(ShaderParameter.MAX_FRAGMENT_TEXTURE_UNITS);
    }
    defines ~= ("#define TEXTURE_ATLAS_UNITS %d".format(maxTextureUnits - 5));
    return defines;

}

StandardShaderModel loadShaderProgram(string path, string name = "")
{
    if(name == "")
	{
	    name = VirtualFS.getFileName(path);
	}
    string sysPath = VirtualFS.getSystemPath(path);
    enum CurrentProcess
    {
        Shared,
        Fragment,
        Vertex,
        None
    }

    StandardShaderModel shader = new StandardShaderModel(name);

    //string shader = readText(path);
    if (!exists(sysPath))
    {
        Logger.LogError("Could not find path: %s", path);
        return shader;
    }
    auto file = File(sysPath);

    auto range = file.byLine();

    CurrentProcess current = CurrentProcess.None;
    string baseVertex = readText(VirtualFS.getSystemPath("$EngineAssets/Shaders/baseVertex.glsl"));
    string baseFragment = readText(
            VirtualFS.getSystemPath("$EngineAssets/Shaders/baseFragment.glsl"));
    string core = readText(VirtualFS.getSystemPath("$EngineAssets/Shaders/core.glsl"));

    string sharedData = "";
    string fragmentData = "";
    string vertexData = "";
    foreach (line; range)
    {
        //writeln(line);
        if (int idx = line.indexOf("#shader") > -1)
        {

            char[][] args = line.split(" ");

            if (args[1].strip() == "shared")
            {
                current = CurrentProcess.Shared;

            }
            else if (args[1].strip() == "vertex")
            {
                current = CurrentProcess.Vertex;

            }
            else if (args[1].strip() == "fragment")
            {
                current = CurrentProcess.Fragment;

            }
            continue;

        }
        string newLine = ("\n %s".format(line));
        if (current == CurrentProcess.Shared)
        {
            sharedData ~= newLine;

        }
        else if (current == CurrentProcess.Vertex)
        {
            vertexData ~= newLine;
        }
        else if (current == CurrentProcess.Fragment)
        {
            fragmentData ~= newLine;
        }

    }
    string vertexShaderDefines = getShaderDefines(ShaderType.VERTEX, shader);
    string fragmentShaderDefines = getShaderDefines(ShaderType.FRAGMENT, shader);
    string vertexText = "#version 460 core\n" ~ sharedData ~ "\n"
        ~ vertexShaderDefines ~ "\n" ~ baseVertex ~ "\n" ~ core ~ vertexData;
    string fragmentText = "#version 460 core\n" ~ sharedData ~ "\n"
        ~ fragmentShaderDefines ~ "\n" ~ baseFragment ~ "\n" ~ core ~ "\n" ~ fragmentData;

    Shader vertexShader = new Shader(ShaderType.VERTEX, vertexText, name ~ " Vertex");
    Shader fragmentShader = new Shader(ShaderType.FRAGMENT, fragmentText, name ~ " Fragment");

    shader.vertexShader = vertexShader;
    shader.fragmentShader = fragmentShader;
    shader.compile();

    return shader;

}
