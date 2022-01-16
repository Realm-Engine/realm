module realm.engine.graphics.core;
import gl3n.linalg;
import std.format;
import realm.engine.graphics.opengl;
private
{
	import realm.engine.asset;
}



alias ShaderType = GShaderType;
alias FrameBufferAttachmentType = GFrameBufferAttachmentType;
alias TextureFilterfunc = GTextureFilterFunc;
alias TextureWrapFunc = GTextureWrapFunc;
alias TextureType = GTextureType;
alias ImageFormat = GImageFormat;
alias Shader = GShader;
alias SamplerObject = GSamplerObject;
alias QueryObject = GQueryObject;
alias State = GState;
alias FrameBuffer = GFrameBuffer;
alias FrameBufferAttachment = GFrameBufferAttachment;
alias PixelBuffer = GPixelBuffer;
alias ShaderPipeline = GShaderPipeline;
alias FrameBufferTarget = GFrameBufferTarget;
alias ShaderProgramModel = GShaderProgramModel;
alias DrawBufferTarget = GDrawBufferTarget;
alias FrameMask = GFrameMask;
alias BlendFuncType = GBlendFuncType;
alias CullFace = GCullFace;
alias PrimitiveShape = GPrimitiveShape;
alias QueryTarget = GQueryTarget;
alias ShaderProgramStages = GShaderProgramStages;
alias ShaderParameter = GShaderParamater;
alias blendFunc = gBlendFunc;
alias blendFuncSeperate = gBlendFuncSeperate;
alias enable =gEnable;
alias disable =gDisable;
alias clear = gClear;
alias cull = gCull;
alias setViewport = gSetViewport;
alias readBuffer = gReadBuffer;
alias bindAttribute = gBindAttribute;
alias enableDebugging = gEnableDebugging;

alias StandardShaderModel = ShaderProgramModel!(ShaderType.VERTEX,ShaderType.FRAGMENT);
alias ComputeShader = ShaderProgramModel!(ShaderType.COMPUTE);

enum VertexType : int
{
	FLOAT = 0x4011,
	FLOAT2 = 0x4021,
	FLOAT3 = 0x4031,
	FLOAT4 = 0x4041,
	INTEGER = 0x4012
}

enum UserDataVarTypes : int
{
	VECTOR = VertexType.FLOAT4,
	MATRIX = 0x4101,
	FLOAT = VertexType.FLOAT,
	TEXTURE2D = 0x101D,
	
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
	TRIANGLE = 3,
	LINES = 2
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
	vec3 normal;
	vec3 tangent;
	int materialId;
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
	
	IFImage* image;
	alias image this;
	int channels;
	TextureFilterfunc filter;
	TextureWrapFunc wrap;
	this(IFImage* image)
	{
		this.image = image;
                
	}

	this(ubyte r, ubyte g, ubyte b, ubyte a, int width, int height)
	{
		import std.range;
		image = new IFImage;
		image.w = width;
		image.h = height;
		image.c = 4;
		image.cinfile =4;
		image.bpc = 8;
		image.e = 0;
		
		image.buf8.length = (image.w * image.h) * image.c;
		for(int i = 0; i < image.w * image.h; i += image.c)
		{
			image.buf8[i..i+4] = [r,g,b,a];
		}
		
	}

	void freeImage()
	{
		image.free();
	}

	void opAssign(vec4 color)
	{
		
	}

}



struct RealmGlobalData
{
  float[16] vp;
  float[4] mainLightDirection;
  float[4] mainLightColor;
  float[16] lightSpaceMatrix;
  float[4] camPosition;
  float[4] camDirection;
  float nearPlane;
  float farPlane;
  float[2] size;
  
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


