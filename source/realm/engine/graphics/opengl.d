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
    MappedRead = GL_MAP_READ_BIT | GL_MAP_PERSISTENT_BIT | GL_MAP_COHERENT_BIT,
    MappedWrite = GL_MAP_WRITE_BIT | GL_MAP_PERSISTENT_BIT | GL_MAP_COHERENT_BIT,
    WriteOnlyTemp = GL_MAP_WRITE_BIT,
    Buffered = GL_DYNAMIC_STORAGE_BIT
}

enum GBufferType : GLenum
{
    Vertex = GL_ARRAY_BUFFER,
    Element =  GL_ELEMENT_ARRAY_BUFFER,
    ShaderStorage = GL_SHADER_STORAGE_BUFFER,
    Uniform = GL_UNIFORM_BUFFER,
    DrawIndirect = GL_DRAW_INDIRECT_BUFFER,
    Query = GL_QUERY_BUFFER,
    PixelBuffer = GL_PIXEL_UNPACK_BUFFER
}

enum GState : GLenum
{
    DepthTest = GL_DEPTH_TEST,
    Blend = GL_BLEND,
    FrameBufferSRGB = GL_FRAMEBUFFER_SRGB,
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

enum bool isMappedBuffer(T) = (T == GBufferUsage.MappedWrite || T == GBufferUsage.WriteOnlyTemp || T == GBufferUsage.MappedRead);

mixin template OpenGLBuffer(GBufferType bufferType, T, GBufferUsage usage)
{
    static assert(isValidBufferTarget!(bufferType),bufferType.stringof ~ " does not have a valid buffer type");
    mixin OpenGLObject;

    private uint ringPtr;
    private size_t ringSize;
    


    static if (usage == GBufferUsage.MappedWrite  || usage == GBufferUsage.MappedRead)
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

        void refreshPointer()
		{
            bind();
            glUnmapBuffer(bufferType);
            mapBuffer();
            unbind();

		}
        
        private void mapBuffer()
        out
		{
            
			GLboolean mapped = getParameter!(GLboolean)(GL_BUFFER_MAPPED);
			assert(mapped == GL_TRUE,"Could not map buffer");
			
			long bufferSize = getParameter!(long)(GL_BUFFER_SIZE);

			assert(bufferSize == ringSize,"Buffer storage allocated less than requested");
		}
        do
		{
			glPtr = cast(T*) glMapBufferRange(bufferType, 0, ringSize, usage);

            Logger.Assert(glPtr !is null,"Could not map buffer: %s", bufferType.stringof);
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
       
        long bufferSize = getParameter!(long)(GL_BUFFER_SIZE);
        
        assert(bufferSize == ringSize,"Buffer storage allocated less than requested");

	}
    do
    {
    
        glBufferStorage(bufferType, size * T.sizeof, null, usage);
        ringPtr = 0;
        ringSize = size * T.sizeof;
        static if (usage == GBufferUsage.MappedWrite || usage == GBufferUsage.MappedRead)
        {
            mapBuffer();
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
        assert(id > 0,"Trying to buffer data to non exsistent buffer");
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



class GShaderPipeline
{
    mixin OpenGLObject;

    void create()
    out
	{
        assert(id > 0, "Failed to create program pipeline");
	}
    do
	{
        glGenProgramPipelines(1, &id);
	}

    void bind()
	{
        glBindProgramPipeline(id);
	}

    void useProgramStages(Args...)(Args models)
	{
        
        foreach(model; models)
		{
            GLenum stage =  model.getShaderStageBits();
            glUseProgramStages(id,stage,model);
		}
        
	}
        

    void unbind()
	{
        glBindProgramPipeline(0);
	}

    void clearStages(GShaderProgramStages stages)
	{
        glUseProgramStages(id,stages,0);
	}

    void validate()
	{
        glValidateProgramPipeline(id);
	}


}

mixin template ParameterQuery(T)
{
    V getParameter(V)(T param)
	{
        V result;
        static if(__traits(isArithmetic,T))
		{
			static if(__traits(isIntegral,V))
			{
				static if(T.sizeof == 4)
				{
					glGetIntegerv(param,&result);
				}
				static if(T.sizeof == 8)
				{
					glGetInteger64v(param,&result);
				}
			}
			static if(__traits(isFloating,V))
			{
				static if(T.sizeof == 4)
				{
					glGetFloatv(param,&result);
				}
				static if(T.sizeof == 8)
				{
					glGetDoublev(param,&result);
				}
			}
		}

        static if(!__traits(isArithmetic,T))
		{
            glGetBooleanv(param,&result);
		}
        return result;

	}

	V getParameter(V)(T param,uint index)
	{
        V result;
        static if(__traits(isArithmetic,T))
		{
			static if(__traits(isIntegral,V))
			{
				static if(T.sizeof == 4)
				{
					glGetIntegeri_v(param,index,&result);
				}
				static if(T.sizeof == 8)
				{
					glGetInteger64i_v(param,index,&result);
				}
			}
			static if(__traits(isFloating,V))
			{
				static if(T.sizeof == 4)
				{
					glGetFloati_v(param,index,&result);
				}
				static if(T.sizeof == 8)
				{
					glGetDoublei_v(param,index,&result);
				}
			}
		}

        static if(!__traits(isArithmetic,T))
		{
            glGetBooleani_v(param,index,&result);
		}
        return result;

	}


}


class GShaderProgramModel(T...)
{
    int[string] samplerUniformCache;
    mixin OpenGLObject;

    private GShader[GShaderType] _shaders;

    static foreach(Type; T)
	{
        static assert(isValidShaderType!(Type) == true);
        static if(Type == GShaderType.VERTEX)
		{
            private GShader _vertexShader;
            @property vertexShader(GShader shader)
			{
                _shaders[Type] = shader;
			}
		}
		static if(Type == GShaderType.FRAGMENT)
		{
            private GShader _fragmentShader;
            @property fragmentShader(GShader shader)
			{
                 _shaders[Type] = shader;
			}
		}
		static if(Type == GShaderType.COMPUTE)
		{
            private GShader _computeShader;
            @property computeShader(GShader shader)
			{
                 _shaders[Type] = shader;
			}

            void dispatch(uint groupsX, uint groupsY, uint groupsZ)
			{
                glDispatchCompute(groupsX,groupsY,groupsZ);
			}
		}
	}

    private string _name;

    this(string name)
	{
        _name = name;
		id = glCreateProgram();
        glProgramParameteri(id,GL_PROGRAM_SEPARABLE,GL_TRUE);
       
	}

    void compile()
	{
        auto md5 = new MD5Digest;
        string nameHash = toHexString(md5.digest(_name));
        string sourceHash = "";
		foreach(shader;_shaders)
		{
			sourceHash ~= toHexString(md5.digest(shader.sourceHash));
		}
		ubyte[] binaryCache = checkCache(nameHash,sourceHash);
        if(binaryCache.length > 0)
        {

			loadProgramBinary(&binaryCache);
			foreach (shader; _shaders)
			{
				glAttachShader(this, shader);

			}
        }

        else
		{
			foreach(shader; _shaders)
			{
				shader.compile();
				glAttachShader(this,shader);
			}
            glLinkProgram(this);
            
            string fileName = "Cache/Shaders/%s_%s.bin".format(nameHash,sourceHash);
            if(!exists(fileName))
            {
                Logger.LogInfo("Writing program binary %s to cache",_name);
                
                ubyte[] binary = getBinary();
                std.file.write(fileName,binary);
            }
		}


        
        foreach(shader; _shaders)
		{
			glDetachShader(this,shader);
			glDeleteShader(shader);
		}

		char[256] result;
        int success;
        glGetProgramiv(this, GL_LINK_STATUS, &success);
        if (success == 0)
        {
            glGetProgramInfoLog(this, 256, null, result.ptr);
            Logger.LogError("Could not link program: %s\nError:%s",_name, result);
        }
        else
        {
            Logger.LogInfo("Program %s linked", _name);
        }
	}

    void loadProgramBinary(ubyte[]* binary)
    do
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
            Logger.LogInfo("Loading program %s from binary", _name);
            glProgramBinary(id,cast(GLenum)formats[0],cast(void*)binary.ptr,cast(int)binary.length);
        }
    }

	ubyte[] checkCache(string nameHash,string sourceHash)
    {
       
        string fileName = "Cache/Shaders/%s_%s.bin".format(nameHash,sourceHash);
        ubyte[] result;
        if(exists(fileName))
        {

            result = cast(ubyte[])read(fileName);
            Logger.LogInfo("Binary for program %s found",_name);
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

    void use()
	{
        glUseProgram(this);
	}
    void unbind()
	{
        glUseProgram(0);
	}

    private GLenum getShaderStageBits()
	{
        GLenum result;
        static foreach(Type; T)
		{
            static if(Type == GL_VERTEX_SHADER)
			{
                result |= GL_VERTEX_SHADER_BIT;
			}
            static if(Type == GL_FRAGMENT_SHADER)
			{
                result |= GL_FRAGMENT_SHADER_BIT;
			}
            static if(Type == GL_COMPUTE_SHADER)
			{
                result |= GL_COMPUTE_SHADER_BIT;
			}
		}
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
    
    void setUniformFloat(int loc, float value)
    in(loc >= 0, "Must use valid uniform location")
	{
        glUniform1f(loc,value);


	}

    void setUniformInts(int loc, int[] values)
    in(loc >= 0, "Must use valid uniform location")
	{
        glUniform1iv(loc,cast(int)values.length,cast(const (int)*)values.ptr);
	}

	static int getNumSupportedProgramBinaryFormats()
    {
        int result;
        glGetIntegerv(GL_NUM_PROGRAM_BINARY_FORMATS,&result);
        return result;
    }

    void bindImageWrite(GSamplerObject!(TextureType.TEXTURE2D)* sampler,int level,int location,bool layered = false, int layer = 0)
	{
        if(sampler is null)
		{
            glBindImageTexture(location,0,level,layered ? GL_TRUE : GL_FALSE,layer,GL_WRITE_ONLY,sampler.internalFormat);
            return;
		}
        glBindImageTexture(location,sampler.ID,level,layered ? GL_TRUE : GL_FALSE,layer,GL_WRITE_ONLY,sampler.internalFormat);
	}

    void waitImageWriteComplete()
	{
        glMemoryBarrier(GL_ALL_BARRIER_BITS);
	}




    mixin ParameterQuery!(GShaderParameter);

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
            desc.fmt = ImageFormat.RGB8;
            
        }
        else if(type == GFrameBufferAttachmentType.DEPTH_ATTACHMENT)
        {
            desc.fmt = ImageFormat.DEPTH;

        }
        else if(type == GFrameBufferAttachmentType.DEPTH_STENCIL_ATTACHMENT)
        {
            desc.fmt = ImageFormat.DEPTH_STENCIL;
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

struct GPixelBuffer(GBufferUsage usage)
{
    mixin OpenGLBuffer!(GBufferType.PixelBuffer,ubyte,usage);

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

struct GShaderStorage(T, GBufferUsage usage)
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
    import std.meta;
    enum is3dTexture = (target == GTextureType.TEXTURE2DARRAY || target == GTextureType.TEXTURE3D);
    mixin OpenGLObject;
    private GLenum wrapFunc;
    private GLenum filterFunc;
    private GLenum internalFormat;
    private GLenum format;
    private GLenum dataType;
    private int mipLevels;
    private int texSlot;
    private int channels;
    private int bpc;
    int width;
    int height;
    bool destroyed;
    
    invariant()
	{
        if(!destroyed)
		{
            assert(texSlot >= 0,"Texture slot must be positive");
		}

        assert(mipLevels >= 0, "Mipmap count must be positive");
	}

    @property filter(GTextureFilterFunc func)
	{
        glBindTexture(target,id);
        filterFunc = func;
		glTexParameteri(target, GL_TEXTURE_MIN_FILTER, func);
        glTexParameteri(target, GL_TEXTURE_MAG_FILTER, func);
        glBindTexture(0,id);
	}
    @property wrap(GTextureWrapFunc func)
	{
		glBindTexture(target,id);
        wrapFunc = func;
		glTexParameteri(target, GL_TEXTURE_WRAP_S, func);
        glTexParameteri(target, GL_TEXTURE_WRAP_T, func);
        glBindTexture(0,id);
	}

    @property border(float[4] borderColor)
	{
		glBindTexture(target,id);
		glTexParameterfv(target, GL_TEXTURE_BORDER_COLOR, borderColor.ptr);
        glBindTexture(0,id);
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
        internalFormat = desc.fmt.sizedFormat;
        dataType = sizeFormatToGLDataType(desc.fmt.sizedFormat);
        format = desc.fmt.baseFormat;
        mipLevels = 3;
        channels = desc.fmt.channels;
        bpc = desc.fmt.bpc;
        glTexParameteri(target, GL_TEXTURE_WRAP_S, wrapFunc);
        glTexParameteri(target, GL_TEXTURE_WRAP_T, wrapFunc);
        glTexParameteri(target, GL_TEXTURE_MIN_FILTER, filterFunc);
        glTexParameteri(target, GL_TEXTURE_MAG_FILTER, filterFunc);
        glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
        glPixelStorei(GL_PACK_ALIGNMENT,1);
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
            this.width = width;
            this.height = height;

            glBindTexture(target, 0);

        }
    
        ubyte[] getClearData(float[4] color)
		{
            ubyte[] clearData;
            clearData.length = 4;
            clearData[0] = cast(ubyte)color[0];
            clearData[1] = cast(ubyte)color[1];
			clearData[2] = cast(ubyte)color[2];
			clearData[3] = cast(ubyte)color[3];
            return clearData;

		}

        void clear(T)(int level,T[] color)
		{

            glBindTexture(target,id);
            //ubyte[4] clearColor = [255,255,255,255];
            glClearTexImage(this,level,format,dataType,color.ptr);
            glBindTexture(target,0);

		}

        void clear(T)(int level, int xoffset,int yoffset, int width, int height,T[] color)
		{
            //[4] clearColor = [1,1,1,1];
            glBindTexture(target,id);
            glClearTexSubImage(this,level,xoffset,yoffset,0,width,height,1,format,dataType,color.ptr);
            glBindTexture(target,0);
		}

	
        void uploadSubImage(int level, int xoffset, int yoffset, int width, int height, ubyte* data)
        //in(data !is null)
        {
            //assert(data != null);
            glBindTexture(target, id);
            glTexSubImage2D(target, level, xoffset, yoffset, width, height, format, dataType, data);
            glBindTexture(target, 0);
        }
		void uploadSubImage(int level, int xoffset, int yoffset, int width, int height, ushort* data)
			//in(data !is null)
        {
            //assert(data != null);
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
        in(data !is null)
        {
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

	ubyte[] readPixels(int level)
	{
		ubyte[] result;
        size_t len =  (width * height) * channels * bpc;
        result.length = len;
        bind();
		glGetTexImage(target,level,format,dataType,cast(void*)result.ptr);
        unbind();
        return result;
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
    FRAGMENT = GL_FRAGMENT_SHADER,
    COMPUTE= GL_COMPUTE_SHADER

}

enum bool isValidShaderType(GLenum T) = (T == GL_VERTEX_SHADER || T == GL_FRAGMENT_SHADER || T == GL_COMPUTE_SHADER);

enum GShaderProgramStages : GLenum
{
    VERTEX_STAGE = GL_VERTEX_SHADER_BIT,
    FRAGMENT_STAGE = GL_FRAGMENT_SHADER_BIT,
    COMPUTE_STAGE = GL_COMPUTE_SHADER_BIT,
    TESSELATION_CONTROL = GL_TESS_CONTROL_SHADER_BIT,
    TESSELATION_EVALUATION = GL_TESS_EVALUATION_SHADER_BIT,
    GEOMETRY_STAGE = GL_GEOMETRY_SHADER_BIT,
    ALL_STAGES = GL_ALL_SHADER_BITS
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



enum GBaseImageFormat : GLenum
{
	RED = GL_RED,
	SRGB = GL_RGB,
	RGB = GL_RGB,
	RGBA = GL_RGBA,
	DEPTH_STENCIL = GL_DEPTH_STENCIL,
	DEPTH = GL_DEPTH_COMPONENT,
	SRGB_ALPHA = GL_RGBA
    


}

enum GSizedImageFormat : GLenum
{
    RED8 = GL_R8,
    R16 = GL_R16,
    RGB8 = GL_RGB8,
    RGBA8 = GL_RGBA8,
    RGBA16 = GL_RGBA16,
    RGBA32F = GL_RGBA32F,
    SRGB8 = GL_SRGB8,
    SRGBA8 = GL_SRGB8_ALPHA8,
    DEPTH = GL_DEPTH_COMPONENT,
    DEPTH_STENCIL = GL_DEPTH_STENCIL,
    RED32F = GL_R32F,
    RGB32F = GL_RGB32F

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

enum GShaderParameter : GLenum
{
    COMPUTE_WORK_GROUP_COUNT = GL_MAX_COMPUTE_WORK_GROUP_COUNT,
    COMPUTE_WORK_GROUP_SIZE = GL_MAX_COMPUTE_WORK_GROUP_SIZE,
    MAX_VERTEX_TEXTURE_UNITS = GL_MAX_VERTEX_TEXTURE_IMAGE_UNITS,
    MAX_FRAGMENT_TEXTURE_UNITS = GL_MAX_TEXTURE_IMAGE_UNITS
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

GLenum imageFormatToGLDataType(GBaseImageFormat fmt)
{

    switch (fmt)
    {
		case GBaseImageFormat.RGB:
			return GL_UNSIGNED_BYTE;
		case GBaseImageFormat.RGBA:
			return GL_UNSIGNED_BYTE;
		case GBaseImageFormat.RED:
			return GL_UNSIGNED_BYTE;
		case GBaseImageFormat.DEPTH_STENCIL:
			return GL_DEPTH24_STENCIL8;
		case GBaseImageFormat.DEPTH:
			return GL_FLOAT;
		default:
			return GL_FLOAT;
    }
}



GLenum sizeFormatToGLDataType(GSizedImageFormat fmt)
{
	switch (fmt)
    {
		case GSizedImageFormat.RED8 :
			return GL_UNSIGNED_BYTE;
        case  GSizedImageFormat.RGB8:
            return GL_UNSIGNED_BYTE;
		case  GSizedImageFormat.RGBA8:
            return GL_UNSIGNED_BYTE;
		case  GSizedImageFormat.SRGB8:
            return GL_UNSIGNED_BYTE;
		case  GSizedImageFormat.SRGBA8:
            return GL_UNSIGNED_BYTE;
		case GSizedImageFormat.R16 :
			return GL_UNSIGNED_SHORT;
        case GSizedImageFormat.RGBA16:
			return GL_UNSIGNED_SHORT;
        case GSizedImageFormat.RGBA32F | GSizedImageFormat.RED32F:
            return GL_FLOAT;
		case GSizedImageFormat.DEPTH_STENCIL:
			return GL_DEPTH24_STENCIL8;
		case GSizedImageFormat.DEPTH:
			return GL_FLOAT;
		default:
			return GL_FLOAT;
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
version(Windows)
{
    extern(Windows) private void debugOutput(GLenum source, GLenum type, uint id, GLenum severity,int length, const char* message, const void* userParam) nothrow 
	{
       printf("Error: %s\n",message );
        
	}
}


void gEnableDebugging()
in
{
	int flags;
    glGetIntegerv(GL_CONTEXT_FLAGS,&flags);
    assert((flags & GL_CONTEXT_FLAG_DEBUG_BIT) == GL_CONTEXT_FLAG_DEBUG_BIT,"Enable GLFW window hint 'GLFW_OPENGL_DEBUG_CONTEXT'");
}
do
{
    glEnable(GL_DEBUG_OUTPUT);
    glEnable(GL_DEBUG_OUTPUT_SYNCHRONOUS);
    glDebugMessageCallback(&debugOutput,null);
    glDebugMessageControl(GL_DEBUG_SOURCE_API,GL_DEBUG_TYPE_ERROR,GL_DEBUG_SEVERITY_HIGH,0,null,GL_TRUE);


}