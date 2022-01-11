module realm.engine.graphics.opengl;
import derelict.opengl3.gl3;
import glfw3.api;
import std.container.array;
import std.format;
import std.string;
import std.stdio;
import realm.engine.graphics.core;
import realm.engine.logging;
import std.file ;
import std.format;
import std.digest.md;
struct DrawElementsIndirectCommand
{
    uint count;
    uint instanceCount;
    uint firstIndex;
    uint baseVertex;
    uint baseInstance;
}


mixin template OpenGLObject()
{
    private uint id;

    invariant
	{
        assert(id >= 0,"OpenGL object name error");
	}

    @property uint ID()
    {
        return id;
    }

    alias ID this;
}

enum GBufferUsage : GLenum
{
    MappedWrite = GL_MAP_WRITE_BIT | GL_MAP_PERSISTENT_BIT | GL_MAP_COHERENT_BIT,
    Buffered = GL_DYNAMIC_STORAGE_BIT
}

enum GBufferType : GLenum
{
    Vertex = GL_ARRAY_BUFFER,
    Element =  GL_ELEMENT_ARRAY_BUFFER,
    ShaderStorage = GL_SHADER_STORAGE_BUFFER,
    Uniform = GL_UNIFORM_BUFFER,
    DrawIndirect = GL_DRAW_INDIRECT_BUFFER,
    Query = GL_QUERY_BUFFER
}

enum GState : GLenum
{
    DepthTest = GL_DEPTH_TEST,
    Blend = GL_BLEND,
    None
}

enum bool isValidBufferTarget(GLenum T) = (T == GL_ARRAY_BUFFER 
												  || T == GL_ATOMIC_COUNTER_BUFFER
												  || T == GL_COPY_READ_BUFFER
												  || T == GL_COPY_WRITE_BUFFER
												  || T == GL_DISPATCH_INDIRECT_BUFFER
												  || T == GL_DRAW_INDIRECT_BUFFER
												  || T == GL_ELEMENT_ARRAY_BUFFER
												  || T == GL_PIXEL_PACK_BUFFER
											      || T == GL_PIXEL_UNPACK_BUFFER
											      || T == GL_QUERY_BUFFER
											      || T == GL_SHADER_STORAGE_BUFFER
											      || T == GL_TEXTURE_BUFFER
											      || T ==GL_TRANSFORM_FEEDBACK_BUFFER
											      || T == GL_UNIFORM_BUFFER);


mixin template OpenGLBuffer(GBufferType bufferType, T, GBufferUsage usage)
{
    static assert(isValidBufferTarget!(bufferType));
    mixin OpenGLObject;

    private uint ringPtr;
    private size_t ringSize;
    


    static if (usage == GBufferUsage.MappedWrite)
    {

        private T* glPtr;

        @property ptr()
        {
            return glPtr;

        }

        @property length()
        {
            return (ringSize / T.sizeof);

        }

    }

    void bind()
    {
        glBindBuffer(bufferType, id);

    }

    void unbind()
    {
        glBindBuffer(bufferType, 0);
    }

    void create()
    out(;this.id > 0,"Failed creating buffer")
    {
        glGenBuffers(1, &id);

    }

    

    void store(size_t size)
    in(size > 0, "Buffer size must be positive")
	out
	{
        static if(usage == GBufferUsage.MappedWrite)
		{
			GLboolean mapped = getParameter!(GLboolean)(GL_BUFFER_MAPPED);
			assert(mapped == GL_TRUE,"Could not map buffer");
		}
        long bufferSize = getParameter!(long)(GL_BUFFER_SIZE);
        
        assert(bufferSize == ringSize,"Buffer storage allocated less than requested");

	}
    do
    {
    
        glBufferStorage(bufferType, size * T.sizeof, null, usage);
        ringPtr = 0;
        ringSize = size * T.sizeof;
        static if (usage == GBufferUsage.MappedWrite)
        {
            glPtr = cast(T*) glMapBufferRange(bufferType, 0, ringSize, usage);
            
            Logger.Assert(glPtr !is null,"Could not map buffer: %s", bufferType.stringof);
        }

    }

    private T getParameter(T)(GLenum param)
	{
        import std.traits;
        T val;
        static if(isIntegral!(T))
		{
            static if(T.sizeof == 4 || T.sizeof == 1)
			{
                glGetNamedBufferParameteriv(id,param,cast(GLint*) &val);
			}
            static if(T.sizeof == 8)
			{
                glGetNamedBufferParameteri64v(id,param,&val);
			}
		}  
        return val;
	}

    uint bufferData(T* data, size_t length)
	in
	{
        assert(length <= ringSize,"Cant write more data than allocated");
	}
    do
    {
        uint dataStart = ringPtr;
        glBufferSubData(bufferType, ringPtr, length * T.sizeof, data);
        ringPtr += length * T.sizeof % ringSize;
        return dataStart;

    }

    void invalidate()
    {
        glInvalidateBufferData(id);
        ringPtr = 0;
    }

    @property elementSize()
    {
        return T.sizeof;
    }

}


class GShader
{
    mixin OpenGLObject;
    private string name;
    private GShaderType type;
    string sourceHash;
    string nameHash;
    string source;
    ubyte[] checkCache(string source,string name)
    {

        if(!exists("Cache/Shaders"))
        {
            Logger.LogInfo("Creating shader cache folder");
            mkdir("Cache/Shaders");
            
        }
        ubyte[] result;
        auto md5 = new MD5Digest();

        sourceHash = toHexString(md5.digest(source));
        nameHash = toHexString(md5.digest(name));
        string fileName = "Cache/Shaders/%s_%s.bin".format(nameHash,sourceHash);
        if(exists(fileName))
        {
            result = cast(ubyte[])read(fileName);
        }
        return result;
    }

    this(GShaderType type, string shaderSource, string name)
    {
        this.type = type;
        this.name = name;
        ubyte[] binary = checkCache(shaderSource,name);
        if(binary.length > 0)
        {
            loadShaderBinary();
        }
        this.source = shaderSource;
        id = glCreateShader(type);
        //compile(shaderSource);
        
    }

    static int getNumSupportedShaderBinaryFormats()
    {
        int result;
        glGetIntegerv(GL_NUM_SHADER_BINARY_FORMATS,&result);
        return result;
    }
    //Finish
    void loadShaderBinary()
    {
        Logger.LogInfo("Loading binary for shader %s",name);
        id = glCreateShader(type);
        int numFormats = getNumSupportedShaderBinaryFormats();
        Logger.LogInfo("Num supported binary formats: %d",numFormats);
        if(numFormats <= 0)
        {
            Logger.LogError("Loading shader binaries not supported on system");
            return;
        }
        int format;
        //glGetIntegeri_v(GL_PROGRAM_BINARY_FORMATS,0,&format);
        
    }

    void compile()
    {
        Logger.LogInfo("Compiling shader %s",name);

        //id = glCreateShader(type);
        const(char*)[] strings;
        strings ~= source.toStringz();
        glShaderSource(id, 1, strings.ptr, null);
        glCompileShader(id);
        int status;
        glGetShaderiv(id, GL_COMPILE_STATUS, &status);
        
        if (status == GL_FALSE)
        {
            Logger.LogError("Error compiling shader");
            int length = -1;
            glGetShaderiv(id, GL_INFO_LOG_LENGTH, &length);
            char[] message;
            if (length > -1)
            {
                message.length = length;
                glGetShaderInfoLog(id, length, &length, message.ptr);
                char[] dstr = fromStringz(message);
                Logger.LogError("Name: %s error:\n%s",name, dstr);
            }

        }

    }

}



class GShaderProgram
{
    mixin OpenGLObject;

    private string name;
    private GShader[2] shaders;
    int[string] samplerUniformCache;

    void use()
    {
        glUseProgram(this);
    }

    void loadProgramBinary(ubyte[]* binary)
    {
        int numFormats = getNumSupportedProgramBinaryFormats();
        ubyte[] result;
        if(numFormats <= 0)
        {
            Logger.LogError("Loading program binary not supported on system");
            
        }
        else 
        {
            int length;
            glGetProgramiv(id,GL_PROGRAM_BINARY_LENGTH,&length);
            result.length = length;
            int[] formats;
            formats.length = numFormats;
            int size;
            glGetIntegerv(GL_PROGRAM_BINARY_FORMATS,formats.ptr);
            Logger.LogInfo("Loading program %s from binary", name);
            glProgramBinary(id,cast(GLenum)formats[0],cast(void*)binary.ptr,cast(int)binary.length);
        }
    }

    this(GShader vertex, GShader fragment, string name)
    {
        id = glCreateProgram();
        this.name = name;

        shaders[0] = vertex;
        shaders[1] = fragment;
        foreach (shader; shaders)
        {
            glAttachShader(this, shader);

        }
        ubyte[] binaryCache = checkCache(vertex,fragment,name);
        if(binaryCache.length > 0)
        {
            
            loadProgramBinary(&binaryCache);
           
        }
        else
        {
            
            shaders[0].compile();
            shaders[1].compile();
            
            glLinkProgram(this);
            
            foreach (shader; shaders)
            {
                glDeleteShader(shader);
            }
            
            auto md5 = new MD5Digest();
            string nameHash = toHexString(md5.digest(name));
            string sourceHash = toHexString(md5.digest(vertex.sourceHash ~ fragment.sourceHash));
            string fileName = "Cache/Shaders/%s_%s.bin".format(nameHash,sourceHash);
            if(!exists(fileName))
            {
                Logger.LogInfo("Writing program binary %s to cache",name);
                ubyte[] binary = getBinary();
                std.file.write(fileName,binary);
            }
        }
        char[256] result;
        int success;
        glGetProgramiv(this, GL_LINK_STATUS, &success);
        if (!success)
        {
            glGetProgramInfoLog(this, 256, null, result.ptr);
            Logger.Assert(true,"Could not link program: %s\nError:%s",name, result);
        }
        else
        {
            Logger.LogInfo("Program %s linked", name);
        }
        
        int numUniforms = 0;
        glGetProgramiv(this, GL_ACTIVE_UNIFORMS, &numUniforms);
        for (uint i = 0; i < numUniforms; i++)
        {
            int type;
            glGetActiveUniformsiv(this, 1, &i, GL_UNIFORM_TYPE, &type);
            if (type == GL_SAMPLER_2D)
            {
                GLint nameLen = 0;
                glGetActiveUniformsiv(this, 1, &i, GL_UNIFORM_NAME_LENGTH, &nameLen);
                char[64] uniformName;
                name.length = nameLen + 1;
                glGetActiveUniformName(this, i, nameLen, &nameLen, uniformName.ptr);
                GLint location = glGetUniformLocation(this, uniformName.ptr);
                samplerUniformCache[fromStringz(uniformName).idup] = location;
            }
        }
    

    }

    ubyte[] checkCache(GShader vertex, GShader fragment, string name)
    {
        auto md5 = new MD5Digest();
        string nameHash = toHexString(md5.digest(name));
        string sourceHash = toHexString(md5.digest(vertex.sourceHash ~ fragment.sourceHash));
        string fileName = "Cache/Shaders/%s_%s.bin".format(nameHash,sourceHash);
        ubyte[] result;
        if(exists(fileName))
        {
            
            result = cast(ubyte[])read(fileName);
            Logger.LogInfo("Binary for program %s found",name);
        }
        
        return result;
    }

    ubyte[] getBinary()
    {
        int numFormats = getNumSupportedProgramBinaryFormats();
        ubyte[] result;
        if(numFormats <= 0)
        {
            Logger.LogError("Loading program binary not supported on system");
            return result;

        }
        int length;
        glGetProgramiv(id,GL_PROGRAM_BINARY_LENGTH,&length);
        result.length = length;
        int[] formats;
        formats.length = numFormats;
        int size;
        glGetIntegerv(GL_PROGRAM_BINARY_FORMATS,formats.ptr);
        glGetProgramBinary(id,cast(int)result.length,&size,cast(GLenum*)&formats[0],cast(void*)result.ptr);
        return result;
        
    }

    static int getNumSupportedProgramBinaryFormats()
    {
        int result;
        glGetIntegerv(GL_NUM_PROGRAM_BINARY_FORMATS,&result);
        return result;
    }
    int uniformLocation(string uniform)
    {
        int* loc = (uniform in samplerUniformCache);
        if (loc !is null)
        {
            return *loc;
        }

        samplerUniformCache[uniform] = glGetUniformLocation(this, toStringz(uniform));
        return uniformLocation(uniform);

    }

    void setUniformInt(int loc, int value)
	in(loc >=0,"Must use valid uniform location")
    {
        glUniform1i(loc, value);
    }

}

struct GFrameBufferAttachment
{
    GSamplerObject!(GTextureType.TEXTURE2D) texture;
    this(GFrameBufferAttachmentType type,int width, int height)
    {
        texture.create();
        TextureDesc desc;
        desc.wrap = GTextureWrapFunc.CLAMP_TO_BORDER;
        desc.filter = GTextureFilterFunc.LINEAR;
        if(type == GFrameBufferAttachmentType.COLOR_ATTACHMENT)
        {
            desc.fmt = GImageFormat.RGB;
            
        }
        else if(type == GFrameBufferAttachmentType.DEPTH_ATTACHMENT)
        {
            desc.fmt = GImageFormat.DEPTH;

        }
        else if(type == GFrameBufferAttachmentType.DEPTH_STENCIL_ATTACHMENT)
        {
            desc.fmt = GImageFormat.DEPTH_STENCIL;
        }
        texture.textureDesc = desc;
        texture.store(width,height);
        texture.uploadImage(0,0,null);
    }
}

struct GFrameBuffer
{
    mixin OpenGLObject;
    GFrameBufferAttachment[GFrameBufferAttachmentType] fbAttachments;
    private int fbWidth;
    private int fbHeight;
    @property width()
    {
        return fbWidth;
    }
    @property height()
    {
        return fbHeight;
    }
    void create(GFrameBufferAttachmentType[] attachmentTypes)(int width, int height)
	in(width * height >0,"Framebuffer area must be bigger than 0")
    {
        import std.algorithm.searching :find;
        this.fbWidth = width;
        this.fbHeight = height;
        glGenFramebuffers(1, &id);
        glBindFramebuffer(GL_FRAMEBUFFER,id);
        foreach (type; attachmentTypes)
        {
            GFrameBufferAttachment attachment =  GFrameBufferAttachment(type,width,height);
            
            fbAttachments[type]= attachment;
            attachment.texture.bind();
            glFramebufferTexture2D(GL_FRAMEBUFFER,type,GL_TEXTURE_2D,attachment.texture.ID(),0);
            if(attachmentTypes.find(GFrameBufferAttachmentType.COLOR_ATTACHMENT).empty)
			{
                glDrawBuffer(GL_NONE);
                glReadBuffer(GL_NONE);
			}
            attachment.texture.unbind();
        }
        Logger.Assert(glCheckFramebufferStatus(GL_FRAMEBUFFER) == GL_FRAMEBUFFER_COMPLETE,"Framebuffer %d not complete error: %d",id, glCheckFramebufferStatus(GL_FRAMEBUFFER));
        glBindFramebuffer(GL_FRAMEBUFFER,0);

    }

    void bind(GFrameBufferTarget target)
    {
        glBindFramebuffer(target, this);
    }

    void unbind(GFrameBufferTarget target)
    {
        glBindFramebuffer(target, 0);
    }

    void blitToScreen(GFrameMask mask)
    {
        bind(FrameBufferTarget.READ);
        glBindFramebuffer(FrameBufferTarget.DRAW,0);
        glBlitFramebuffer(0,0,width,height,0,0,width,height,mask,GL_LINEAR);
    }

    void refresh()
    {
        foreach(attachment; fbAttachments)
        {
            attachment.texture.uploadImage(0,0,null);
        }
    }

    void copyToTexture2D(GSamplerObject!(TextureType.TEXTURE2D) texture, int level,int xoffset, int yoffset, int width, int height)
    {
        bind(GFrameBufferTarget.READ);
        glReadBuffer(GL_COLOR_ATTACHMENT0);
        texture.bind();
        glCopyTexSubImage2D(GL_TEXTURE_2D,level,xoffset,yoffset,0,0,width,height);
        texture.unbind();
        unbind(GFrameBufferTarget.READ);
    }

    ~this()
    {
        glDeleteFramebuffers(1, &id);
    }


}

struct VertexBuffer(T, GBufferUsage usage)
{
    mixin OpenGLBuffer!(GBufferType.Vertex, T, usage);
    private uint size;
}

struct ElementBuffer(GBufferUsage usage)
{
    mixin OpenGLBuffer!(GBufferType.Element, uint, usage);
    private uint size;

}

struct ShaderBlock
{

    mixin OpenGLBuffer!(GBufferType.Uniform, RealmGlobalData, GBufferUsage.Buffered);
    void bindBase(uint bindPoint)
    {
        glBindBufferBase(GL_UNIFORM_BUFFER, bindPoint, id);
    }

}

struct ShaderStorage(T, GBufferUsage usage)
{
    mixin OpenGLBuffer!(GBufferType.ShaderStorage, T, usage);
    void bindBase(uint bindPoint)
    {
        glBindBufferBase(GL_SHADER_STORAGE_BUFFER, bindPoint, id);

    }
}

struct DrawIndirectCommandBuffer(GBufferUsage usage)
{
    mixin OpenGLBuffer!(GBufferType.DrawIndirect, DrawElementsIndirectCommand, usage);
}


struct GSamplerObject(GTextureType target)
{
    enum is3dTexture = (target == GTextureType.TEXTURE2DARRAY || target == GTextureType.TEXTURE3D);
    mixin OpenGLObject;
    private GLenum wrapFunc;
    private GLenum filterFunc;
    private GLenum internalFormat;
    private GLenum format;
    private GLenum dataType;
    private int mipLevels;
    private int texSlot;
    int width;
    int height;
    bool destroyed;
    
    invariant()
	{
        assert(texSlot >= 0,"Texture slot must be positive");
        assert(mipLevels >= 0, "Mipmap count must be positive");
	}


    static if (is3dTexture)
    {
        int depth;
    }
    @property textureDesc(TextureDesc desc)
    {
        glBindTexture(target, id);
        wrapFunc = desc.wrap;
        filterFunc = desc.filter;
        internalFormat = imageFormatToInternalFormat(desc.fmt);
        dataType = imageFormatToGLDataType(desc.fmt);
        format = desc.fmt;
        mipLevels = 3;
        glTexParameteri(target, GL_TEXTURE_WRAP_S, wrapFunc);
        glTexParameteri(target, GL_TEXTURE_WRAP_T, wrapFunc);
        glTexParameteri(target, GL_TEXTURE_MIN_FILTER, filterFunc);
        glTexParameteri(target, GL_TEXTURE_MAG_FILTER, filterFunc);
        glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
        glBindTexture(target, 0);

    }

    @property slot(int s)
    {
        texSlot = s;
    }
    @property int slot()
	{
        return texSlot;
	}
    void create()
    {
        glGenTextures(1, &id);
        destroyed = false;

    }

    void setActive()
    {
        glActiveTexture(GL_TEXTURE0 + texSlot);
        glBindTexture(target, id);

    }

    void setActive(int slot)
    {
        glActiveTexture(GL_TEXTURE0 + slot);
        glBindTexture(target,id);
    }

    void bind()
    {
        glBindTexture(target,id);
    }
    void unbind()
    {
        glBindTexture(target,0);
    }

    static if (target == GTextureType.TEXTURE2D)
    {
        void store(int width, int height)
        in(width * height > 0,"Area must be greater than 1")
        {

            glBindTexture(target, id);

            glTexStorage2D(target, mipLevels, internalFormat, width, height);
            glGenerateMipmap(target);
            this.width = width;
            this.height = height;
            //glPixelStorei(GL_PACK_ALIGNMENT, 1);
            glBindTexture(target, 0);

        }

        void uploadSubImage(int level, int xoffset, int yoffset, int width, int height, ubyte* data)
        {
            assert(data != null);
            glBindTexture(target, id);
            glTexSubImage2D(target, level, xoffset, yoffset, width, height, format, dataType, data);
            glBindTexture(target, 0);
        }

        void uploadImage(int level, int border, ubyte* data)
        {
            glBindTexture(target, id);
            glTexImage2D(target, level, internalFormat, width, height, border,
                    format, dataType, data);
            glBindTexture(target, 0);
        }
    }
    static if (target == GTextureType.TEXTURE2DARRAY || target == GTextureType.TEXTURE3D)
    {
        void store(int width, int height, int depth)
        in(width * height > 0,"Area must be greater than 1")
        {
            glBindTexture(target, id);
            glTexStorage3D(target, mipLevels, internalFormat, width, height, depth);
            glBindTexture(target, 0);
            target.glGenerateMipmap();
        }

        void uploadSubImage(int level, int xoffset, int yoffset, int zoffset,int width, int height, int depth, ubyte* data)
        {
            assert(data != null);
            glBindTexture(target, id);
            glTexSubImage3D(target, level, xoffset, yoffset, zoffset, width,
                    height, depth, format, dataType, data);
            glBindTexture(target, 0);
        }

    }

    static if(target == GTextureType.CUBEMAP)
    {

    }

    void free()
	{
        glDeleteTextures(1,&id);
        destroyed = true;
	}

    void freeTextures(GSamplerObject!(target)*[]textures)
	{
        uint[] ids;
        foreach(texture;textures)
		{
            texture.destroyed = true;
            ids ~= texture.ID;
		}
        glDeleteTextures(cast(int)textures.length,cast(const uint*)ids.ptr);
	}

}

enum GQueryTarget : GLenum
{
    SamplesPassedDepthTest = GL_SAMPLES_PASSED,
    AnySamplesPassedDepthTest = GL_ANY_SAMPLES_PASSED,
    VerticesGenerated = GL_PRIMITIVES_GENERATED,
    TimeElapsed = GL_TIME_ELAPSED
}

struct GQueryObject(bool isBuffer = false)
{
    private GLenum currentQuery;
    private bool queryEnded;
    static if(isBuffer)
	{
        mixin OpenGLBuffer!(GBufferType.Query,int,GBufferUsage.Buffered);
	}
    static if(!isBuffer)
	{
        mixin OpenGLObject;

	}

    

    void begin(GQueryTarget query)
	in(id > 0,"No query object created")
	{

        currentQuery = query;
        static if(isBuffer)
		{
            bind();
		}

        glBeginQuery(query,id);
        queryEnded = false;
        
	}
    void end()
	{
        queryEnded = true;
        glEndQuery(currentQuery);

	}
    
    bool isResultAvailable()
	{
        int result;
        glGetQueryObjectiv(id,GL_QUERY_RESULT_AVAILABLE,&result);
        return (result == GL_TRUE) ? true : false;
	}

    bool tryGetResult(T)(T* result)

	in(queryEnded,"Query needs to end before requesting result")
    in
	{
        import std.traits;
        static assert(isIntegral!(T));
	}
    do
	{
        
        if(isResultAvailable())
		{
         
            static if(T.sizeof == 8)
			{
                static if(__traits(isUnsigned,T))
				{
                    glGetQueryObjectui64v(id,GL_QUERY_RESULT,result);
				}
                static if(!__traits(isUnsigned,T))
				{
                    glGetQueryObjecti64v(id,GL_QUERY_RESULT,result);
				}
                
			}
            static if(T.sizeof == 4)
			{
                static if(__traits(isUnsigned,T))
				{
                    glGetQueryObjectuiv(id,GL_QUERY_RESULT,result);
				}
                static if(!__traits(isUnsigned,T))
				{
                    glGetQueryObjectiv(id,GL_QUERY_RESULT,result);
				}
                
			}

            return true;
		}
        return false;

	}

    

    void create()
    out(;this.id > 0,"Failed creating query object")
	{
        glGenQueries(1,&id);
	}
}

struct VertexArrayObject
{
    mixin OpenGLObject;
    void create()
    out(;this.id > 0,"Failed creating vertex array")
    {
        glGenVertexArrays(1, &id);

    }

    void bind()
    {
        glBindVertexArray(id);
    }

    void unbind()
    {
        glBindVertexArray(0);
    }
}

enum GShaderType : GLenum
{
    VERTEX = GL_VERTEX_SHADER,
    FRAGMENT = GL_FRAGMENT_SHADER

}

enum GFrameBufferAttachmentType : GLenum
{
    COLOR_ATTACHMENT = GL_COLOR_ATTACHMENT0,
    DEPTH_ATTACHMENT = GL_DEPTH_ATTACHMENT,
    STENCIL_ATTACHMENT = GL_STENCIL_ATTACHMENT,
    DEPTH_STENCIL_ATTACHMENT = GL_DEPTH_STENCIL_ATTACHMENT
}

enum GTextureFilterFunc : GLenum
{
    NEAREST = GL_NEAREST,
    LINEAR = GL_LINEAR

}

enum GFrameBufferTarget : GLenum
{
    FRAMEBUFFER = GL_FRAMEBUFFER,
    DRAW = GL_DRAW_FRAMEBUFFER,
    READ = GL_READ_FRAMEBUFFER,
    NONE = GL_NONE
}

enum GTextureWrapFunc : GLenum
{
    CLAMP_TO_EDGE = GL_CLAMP_TO_EDGE,
    CLAMP_TO_BORDER = GL_CLAMP_TO_BORDER,
    REPEAT = GL_REPEAT,
    MIRROR = GL_MIRRORED_REPEAT

}

enum GTextureType : GLenum
{
    CUBEMAP = GL_TEXTURE_CUBE_MAP,
    TEXTURE2D = GL_TEXTURE_2D,
    TEXTURE3D = GL_TEXTURE_3D,
    TEXTURE2DARRAY = GL_TEXTURE_2D_ARRAY

}

enum GImageFormat : GLenum
{
    SRGB = GL_RGB,
    RGB = GL_RGB,
    RGBA8 = GL_RGBA,
    DEPTH_STENCIL = GL_DEPTH_STENCIL,
    DEPTH = GL_DEPTH_COMPONENT

}

enum GDrawBufferTarget : GLenum
{
    NONE = GL_NONE,
    FRONT_LEFT = GL_FRONT_LEFT,
    FRONT_RIGHT = GL_FRONT_RIGHT,
    BACK_LEFT  = GL_BACK_LEFT,
    BACK_RIGHT = GL_BACK_RIGHT,
    COLOR = GL_COLOR_ATTACHMENT0
}

enum GFrameMask : GLenum
{
    COLOR = GL_COLOR_BUFFER_BIT,
    DEPTH = GL_DEPTH_BUFFER_BIT,
    STENCIL = GL_STENCIL_BUFFER_BIT
}

enum GBlendFuncType : GLenum
{
    ZERO = GL_ZERO,
    ONE = GL_ONE,
    SRC_COLOR = GL_SRC_COLOR,
    ONE_MINUS_SRC_COLOR = GL_ONE_MINUS_SRC_COLOR,
    DST_COLOR = GL_DST_COLOR,
    ONE_MINUS_DST_COLOR = GL_ONE_MINUS_DST_COLOR,
    SRC_ALPHA = GL_SRC_ALPHA,
    ONE_MINUS_SRC_ALPHA = GL_ONE_MINUS_SRC_ALPHA,
    CONSTANT_COLOR = GL_CONSTANT_COLOR,
    ONE_MINUS_CONSTANT_COLOR = GL_ONE_MINUS_CONSTANT_COLOR,
    CONSTANT_ALPHA = GL_CONSTANT_ALPHA,
    ONE_MINUS_CONSTANT_ALPHA = GL_ONE_MINUS_CONSTANT_ALPHA
}

enum GPrimitiveShape
{
    TRIANGLE = GL_TRIANGLES,
    LINES = GL_LINES,
    LINES_ADJANCENCY = GL_LINES_ADJACENCY
}

enum GCullFace : GLenum
{
    FRONT = GL_FRONT,
    BACK = GL_BACK
}

GLenum imageFormatToInternalFormat(ImageFormat format)
{
    GLenum result;
    switch (format)
    {

    case GImageFormat.RGB:
        result = GL_RGB8;
        break;
    case GImageFormat.RGBA8:
        result = GL_RGBA8;
        break;

    case GImageFormat.DEPTH_STENCIL:
        result = GL_DEPTH_STENCIL;
        break;
    case GImageFormat.DEPTH:
        result = GL_DEPTH_COMPONENT;
        break;
    default:
        writeln("Unknown format");
        result = GL_RGB;
        break;

    }
    return result;

}

GLenum imageFormatToGLDataType(GImageFormat fmt)
{

    switch (fmt)
    {
    case GImageFormat.RGB:
        return GL_UNSIGNED_BYTE;
    case GImageFormat.RGBA8:
        return GL_UNSIGNED_BYTE;
    case GImageFormat.DEPTH_STENCIL:
        return GL_DEPTH24_STENCIL8;
    case GImageFormat.DEPTH:
        return GL_FLOAT;
    default:
        return GL_FLOAT;
    }
}

void gBindAttribute(VertexAttribute attr, uint stride = 0)
{

    GLenum vertexTypeToGLenum(VertexType type)
    {
        switch (type)
        {
        case VertexType.FLOAT:
            return GL_FLOAT;
        case VertexType.FLOAT2:
            return GL_FLOAT;
        case VertexType.FLOAT3:
            return GL_FLOAT;
        case VertexType.FLOAT4:
            return GL_FLOAT;
        default:
            return GL_FLOAT;

        }
    }

    glEnableVertexAttribArray(attr.index);
    GLenum type = vertexTypeToGLenum(attr.type);
    glVertexAttribPointer(attr.index, shaderVarElements(attr.type), type,
            GL_FALSE, stride, cast(void*) attr.offset);
}

void bindAttribute(alias T)(int index,int offset,int stride )
{
    import gl3n.linalg;
    import gl3n.util;
    import std.traits : isFloatingPoint, isIntegral;
    GLenum type;
    int elements = T.sizeof / 4;
    glEnableVertexAttribArray(index);
    static if(is_vector!(T))
	{
        type = GL_FLOAT;
        glVertexAttribPointer(index,elements, type,GL_FALSE,stride,cast(void*)offset);
	}
    static if(isFloatingPoint!(T))
	{
        type = GL_FLOAT;
        glVertexAttribPointer(index,elements, type,GL_FALSE,stride,cast(void*)offset);
	}
    static if(isIntegral!(T))
	{
        type = GL_INT;
        glVertexAttribIPointer(index,elements, type,stride,cast(void*)offset);
	}

    
    
    
	
}

void drawIndirect(GPrimitiveShape shape = GPrimitiveShape.TRIANGLE)()
{
    glDrawElementsIndirect(GL_TRIANGLES, GL_UNSIGNED_INT, cast(void*) 0);
}

void drawMultiIndirect(GPrimitiveShape shape = GPrimitiveShape.TRIANGLE)(int count)
{
    glMultiDrawElementsIndirect(shape, GL_UNSIGNED_INT, null, count, 0);
}

void drawElements(GPrimitiveShape shape = GPrimitiveShape.TRIANGLE)(uint count)
{
    glDrawElements(shape, count, GL_UNSIGNED_INT, null);
}


void gEnable(GState state)
{
    glEnable(state);
}
void gDisable(GState state)
{
    glDisable(state);
}

static void gDrawBuffers(GDrawBufferTarget[] targets)
{
    glDrawBuffers(cast(int)targets.length,cast(const(GLenum)*)targets.ptr);
}

static void gReadBuffer(GFrameBufferTarget target)
{
    glReadBuffer(target);
}

static void gBlendFunc(GBlendFuncType sfactor, GBlendFuncType dfactor)
{
    glBlendFunc(sfactor, dfactor);
}
static void gBlendFuncSeperate(GBlendFuncType r, GBlendFuncType g, GBlendFuncType b, GBlendFuncType a)
{
    glBlendFuncSeparate(r,g,b,a);
}

static void gClear(GFrameMask mask)
{
    glClear(mask);
}

static void gCull(GCullFace face)
{
    glCullFace(face);
}

static void gSetViewport(int x, int y, int width, int height)
in(width >0,"Viewport width must be positive")
in(height >0,"Viewport width must be positive")
{
    glViewport(x,y,width,height);
}