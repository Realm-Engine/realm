module realm.engine.graphics.opengl;
import derelict.opengl3.gl3;
import glfw3.api;
import std.container.array;
import std.format;
import std.string;
import std.stdio;
import realm.engine.graphics.core;
struct DrawElementsIndirectCommand
{
	uint count;
	uint instanceCount;
	uint firstIndex;
	uint baseVertex;
	uint baseInstance;
}

static this()
{

}

mixin template OpenGLObject()
{
	private uint id;
	@property uint ID(){return id;}
	alias ID this;
}


enum GBufferUsage : GLenum
{
	MappedWrite = GL_MAP_WRITE_BIT | GL_MAP_PERSISTENT_BIT| GL_MAP_COHERENT_BIT,
	Buffered = GL_DYNAMIC_STORAGE_BIT
}

mixin template OpenGLBuffer(GLenum bufferType,T,GBufferUsage usage)
{
	mixin OpenGLObject;
	
	private uint ringPtr;
	private size_t ringSize;

	static if(usage == GBufferUsage.MappedWrite)
	{
		private T* glPtr;

		@property ptr()
		{
			return glPtr;

		}

		@property length()
		{
			return (ringSize/T.sizeof);

		}


	}

	void bind()
	{
		glBindBuffer(bufferType,id);

	}
	void unbind()
	{
		glBindBuffer(bufferType,0);
	}

	void create()
	{
		glGenBuffers(1,&id);
		
	}
	
	void store(size_t size)
	{
		
		glBufferStorage(bufferType,size * T.sizeof,null,usage);
		ringPtr = 0;
		ringSize = size * T.sizeof;
		static if(usage == GBufferUsage.MappedWrite)
		{
			glPtr = cast(T*)glMapBufferRange(bufferType,0,ringSize,usage);
		}
		
	}

	uint bufferData(T* data,size_t length)
	{
		uint dataStart = ringPtr;
		glBufferSubData(bufferType,ringPtr,length * T.sizeof,data);
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


mixin template EnumGL(string name)
{
	mixin("enum %s : GLenum".format(name));
}

class GShader
{
	mixin OpenGLObject;
	private string name;
	private GShaderType type;

	this(GShaderType type,string shaderSource,string name)
	{
		this.type = type;
		compile(shaderSource);
		this.name = name;
	}

	void compile(string source)
	{
		id = glCreateShader(type);
		const (char*)[] strings;
		strings~= source.toStringz();
		glShaderSource(id,1,strings.ptr,null);
		glCompileShader(id);
		int status;
		glGetShaderiv(id,GL_COMPILE_STATUS,&status);
		if(status == GL_FALSE)
		{
			int length = -1;
			glGetShaderiv(id,GL_INFO_LOG_LENGTH,&length);
			char[] message;
			if(length > -1)
			{
				message.length = length;
				glGetShaderInfoLog(id,length,&length,message.ptr);
				char[] dstr = fromStringz(message);
				writeln("Name: %s error:\n%s".format(name,dstr));
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

	this(GShader vertex, GShader fragment,string name)
	{
		id = glCreateProgram();
		this.name = name;
		shaders[0] = vertex;
		shaders[1] = fragment;
		foreach(shader; shaders)
		{
			glAttachShader(this,shader);
		
		}
		glLinkProgram(this);
		foreach(shader;shaders)
		{
			glDeleteShader(shader);
		}
		char[256] result;
		int success;
		glGetProgramiv(this, GL_LINK_STATUS, &success);
		if (!success)
		{
			glGetProgramInfoLog(this, 256, null, result.ptr);
			writeln("Could not link program: %s\nError:%s".format(name,result));
			
		}
		
		int numUniforms= 0;
		glGetProgramiv(this,GL_ACTIVE_UNIFORMS,&numUniforms);
		for(uint i = 0; i < numUniforms; i++)
		{
			
			int type;
			glGetActiveUniformsiv(this,1,&i,GL_UNIFORM_TYPE,&type);
			if(type == GL_SAMPLER_2D)
			{
				GLint nameLen = 0;
				glGetActiveUniformsiv(this,1,&i,GL_UNIFORM_NAME_LENGTH,&nameLen);
				char[64] uniformName;
				name.length = nameLen  + 1;
				glGetActiveUniformName(this,i,nameLen,&nameLen,uniformName.ptr);
				GLint location = glGetUniformLocation(this,uniformName.ptr);
				writeln("Uniform: %s".format(uniformName));
				samplerUniformCache[fromStringz(uniformName).idup] = location;
			}

			
			
		}

	}

}



struct FrameBuffer(GFrameBufferStorage storage,GFrameBufferAttachment attachment)
{
	mixin OpenGLObject;
	
	void create(size_t width, size_t height )
	{
		glGenFramebuffers(1,&this);
	}
	void bind()
	{
		glBindFramebuffer(GL_FRAMEBUFFER,this);
	}
	void unbind()
	{
		glBindFramebuffer(GL_FRAMEBUFFER,0);
	}
	~this()
	{
		glDeleteFramebuffers(1,&this);
	}



}

struct VertexBuffer(T,GBufferUsage usage)
{
	mixin OpenGLBuffer!(GL_ARRAY_BUFFER,T,usage);
	private uint size;
}
struct ElementBuffer(GBufferUsage usage)
{
	mixin OpenGLBuffer!(GL_ELEMENT_ARRAY_BUFFER,uint,usage);
	private uint size;
	
}

struct ShaderBlock
{

	mixin OpenGLBuffer!(GL_UNIFORM_BUFFER,RealmGlobalData,GBufferUsage.Buffered);
	void bindBase(uint bindPoint)
	{
		glBindBufferBase(GL_UNIFORM_BUFFER,bindPoint,id);
	}


	
}

struct ShaderStorage(T,GBufferUsage usage)
{
	mixin OpenGLBuffer!(GL_SHADER_STORAGE_BUFFER,T,usage);
	void bindBase(uint bindPoint)
	{
		glBindBufferBase(GL_SHADER_STORAGE_BUFFER,bindPoint,id);

	}
}

struct DrawIndirectCommandBuffer(GBufferUsage usage)
{
	mixin OpenGLBuffer!(GL_DRAW_INDIRECT_BUFFER,DrawElementsIndirectCommand,usage);
}

struct GTextureObject(GTextureType target)
{
	mixin OpenGLObject;

	


	void create(TextureDesc desc,int width, int height,ubyte[] data)
	{
		glGenTextures(1,&id);
		glBindTexture(target,id);
		glTexParameteri(target,GL_TEXTURE_WRAP_S,desc.wrap);
		glTexParameteri(target,GL_TEXTURE_WRAP_T,desc.wrap);
		glTexParameteri(target,GL_TEXTURE_MIN_FILTER,desc.filter);
		glTexParameteri(target,GL_TEXTURE_MAG_FILTER,desc.filter);
		glTexImage2D(target,0,imageFormatToInternalFormat(desc.fmt),width,height,0,desc.fmt,imageFormatToGLDataType(desc.fmt),data.ptr);
		glBindTexture(target,0);
		


	}
}

struct GSamplerObject(GTextureType target)
{
	mixin OpenGLObject;
	private GLenum wrapFunc;
	private GLenum filterFunc;
	private GLenum internalFormat;
	private GLenum format;
	private GLenum dataType;
	private int mipLevels;
	@property textureDesc(TextureDesc desc)
	{
		glBindTexture(target,id);
		wrapFunc = desc.wrap;
		filterFunc = desc.filter;
		internalFormat = imageFormatToInternalFormat(desc.fmt);
		dataType = imageFormatToGLDataType(desc.fmt);
		format = desc.fmt;
		mipLevels = desc.mipLevels;
		glTexParameteri(target,GL_TEXTURE_WRAP_S,wrapFunc);
		glTexParameteri(target,GL_TEXTURE_WRAP_T,wrapFunc);
		glTexParameteri(target,GL_TEXTURE_MIN_FILTER,filterFunc);
		glTexParameteri(target,GL_TEXTURE_MAG_FILTER,filterFunc);
		glBindTexture(target,0);

	}
	void create()
	{
		glGenTextures(1,&id);
		
	}

	static if(target == GTextureType.TEXTURE2D)
	{
		void store(int width, int height)
		{
			glBindTexture(target,id);
			glTexStorage2D(target,mipLevels,internalFormat,width,height);
			glBindTexture(target,0);
		}

		void uploadSubImage(int level,int xoffset,int yoffset,int width, int height,ubyte[] data)
		{
			glBindTexture(target,id);
			glTexSubImage2D(target,level,xoffset,yoffset,width,height,format,dataType,data.ptr);
			glBindTexture(target,0);
		}
	}
	static if(target == GTextureType.TEXTURE2DARRAY || target== GTextureType.TEXTURE3D)
	{
		void store(int width, int height, int depth)
		{
			glBindTexture(target,id);
			glTexStorage3D(target,mipLevels,internalFormat,width,height,depth);
			glBindTexture(target,0);
		}

		void uploadSubImage(int level, int xoffset, int yoffset,int zoffset,int width, int height,int depth,ubyte[] data)
		{
			glBindTexture(target,id);
			glTexSubImage3D(target,level,xoffset,yoffset,zoffset,width,height,depth,format,dataType,data.ptr);
			glBindTexture(target,0);
		}

	}

	

	
	 
	

}

struct VertexArrayObject
{
	mixin OpenGLObject;
	void create()
	{
		glGenVertexArrays(1,&id);

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

enum GFrameBufferAttachment : GLenum
{
	COLOR_ATTACHMENT = GL_COLOR_ATTACHMENT0,
	DEPTH_ATTACHMENT = GL_DEPTH_ATTACHMENT,
	STENCIL_ATTACHMENT = GL_STENCIL_ATTACHMENT,
	DPETH_STENCIL_ATTACHMENT = GL_DEPTH_STENCIL_ATTACHMENT
}

enum GTextureFilterFunc : GLenum
{
	NEAREST = GL_NEAREST,
	LINEAR = GL_LINEAR

}

enum GTextureWrapFunc : GLenum
{
	CLAMP_TO_EDGE = GL_CLAMP_TO_EDGE,
	CLAMP_TO_BORDER = GL_CLAMP_TO_BORDER,
	REPEAT = GL_REPEAT,

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
 
GLenum imageFormatToInternalFormat(ImageFormat format)
{
	GLenum result;
	switch(format)
	{

		case GImageFormat.RGB:
			result = GL_RGB;
			break;
		case GImageFormat.RGBA8:
			result = GL_RGBA;
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
	
	switch(fmt)
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



void bindAttribute(VertexAttribute attr,uint stride = 0)
{

	GLenum vertexTypeToGLenum(VertexType type)
	{
		switch(type)
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
	glVertexAttribPointer(attr.index,shaderVarElements(attr.type),type,GL_FALSE,stride,cast(void*)attr.offset);
}

void drawIndirect()
{
	glDrawElementsIndirect(GL_TRIANGLES,GL_UNSIGNED_INT,cast(void*)0);
}

void drawMultiIndirect(int count)
{
	glMultiDrawElementsIndirect(GL_TRIANGLES,GL_UNSIGNED_INT,null,count,0);
}

void drawElements(uint count)
{
	glDrawElements(GL_TRIANGLES,count,GL_UNSIGNED_INT,null);
}