module realm.engine.graphics.core;
import gl3n.linalg;
import std.format;
import realm.engine.graphics.opengl;
import realm.engine.asset;
alias ShaderType = GShaderType;
alias FrameBufferAttachment = GFrameBufferAttachment;
alias TextureFilterfunc = GTextureFilterFunc;
alias TextureWrapFunc = GTextureWrapFunc;
alias TextureType = GTextureType;
alias ImageFormat = GImageFormat;
alias Shader = GShader;
alias ShaderProgram = GShaderProgram;
alias TextureObject = GTextureObject;
alias SamplerObject = GSamplerObject;
enum VertexType : int
{
	FLOAT = 0x4011,
	FLOAT2 = 0x4021,
	FLOAT3 = 0x4031,
	FLOAT4 = 0x4041
}

enum UserDataVarTypes : int
{
	VECTOR = VertexType.FLOAT4,
	MATRIX = 0x4101,
	FLOAT = VertexType.FLOAT,
	TEXTURE2D = 0x101F

	

}

enum AttributeSlot
{
	POSITION,
	TEXCOORD,
	NORMAL,
	TANGENT

}

enum MeshTopology : int
{
	TRIANGLE = 3
}


enum GFrameBufferStorage
{
	FB_TEXTURE,
	FB_RENDERBUFFER
};

struct RealmVertex
{	

	vec3 position;
	vec2 texCoord;
	/*
	vec3 normal;
	vec2 uv;
*/
}



struct VertexAttribute
{
	VertexType type;
	uint offset;
	uint index;


	
}

struct TextureDesc
{
	ImageFormat fmt;
	TextureFilterfunc filter;
	TextureWrapFunc wrap;
	int mipLevels;
}

class Texture2D
{
	private SamplerObject!(TextureType.TEXTURE2D) handle;
	Image image;
	alias image this;
	int channels;
	ImageFormat format;
	TextureFilterfunc filter;
	TextureWrapFunc wrap;
	this(Image image, TextureDesc desc)
	{
		format = desc.fmt;
		filter = desc.filter;
		wrap = desc.wrap;
	}

}

struct RealmGlobalData
{
	mat4 viewProjection;

}


pragma(inline)
static int shaderVarBytes(VertexType var)
{
	return (var >> 8) >> 4;
}

pragma(inline)
static int shaderVarElements(VertexType var)
{
	return (var & 0x0FF0) >> 4;
}

pragma(inline)
static int shaderVarType(VertexType var)
{
	return (var & 0x000F);
}

pragma(inline)
static int shaderVarSize(VertexType var)
{
	return shaderVarBytes(var) * shaderVarElements(var);
}

