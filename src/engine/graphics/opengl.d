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

mixin template OpenGLBuffer(GLenum bufferType,T)
{
	mixin OpenGLObject;
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
		
		glBufferStorage(bufferType,size * T.sizeof,null,GL_DYNAMIC_STORAGE_BIT);
		
	}

	void bufferData(T* data,uint offset,size_t length)
	{
		
		glBufferSubData(bufferType,offset * T.sizeof,length * T.sizeof,data);
		

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

struct VertexBuffer(T)
{
	mixin OpenGLBuffer!(GL_ARRAY_BUFFER,T);
	private uint size;
}
struct ElementBuffer
{
	mixin OpenGLBuffer!(GL_ELEMENT_ARRAY_BUFFER,uint);
	private uint size;
	
}

struct ShaderBlock
{
	mixin OpenGLObject;
	private uint size;
	private uint refIndex;
	private string name;
}

struct DrawIndirectCommandBuffer
{
	mixin OpenGLBuffer!(GL_DRAW_INDIRECT_BUFFER,DrawElementsIndirectCommand);
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

enum GImageType : GLenum
{
	CUBEMAP = GL_TEXTURE_CUBE_MAP,
	TEXTURE2D = GL_TEXTURE_2D,
	TEXTURE3D = GL_TEXTURE_3D,
	TEXTURE2DARRAY = GL_TEXTURE_2D_ARRAY

}

enum GImageFormat : GLenum
{
	RGB = GL_RGB,
	RGBA8 = GL_RGBA,
	SRGB = GL_SRGB,
	DEPTH_STENCIL = GL_DEPTH_STENCIL,
	DEPTH = GL_DEPTH_COMPONENT
}

GLenum imageFormatToGLDataType(GImageFormat fmt)
{
	switch(fmt)
	{
		case GImageFormat.RGB:
			return GL_UNSIGNED_BYTE;
		case GImageFormat.RGBA8:
			return GL_UNSIGNED_BYTE;
		case GImageFormat.SRGB:
			return GL_UNSIGNED_BYTE;
		case GImageFormat.DEPTH_STENCIL:
			return GL_DEPTH24_STENCIL8;
		case GImageFormat.DEPTH:
			return GL_FLOAT;
		default:
			return GL_FLOAT;
	}
}

void bindAttribute(VertexAttribute attr)
{
	glEnableVertexAttribArray(attr.index);
	GLenum type = attr.type;
	glVertexAttribPointer(attr.index,shaderVarElements(attr.type),GL_FLOAT,GL_FALSE,0,cast(void*)0);


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