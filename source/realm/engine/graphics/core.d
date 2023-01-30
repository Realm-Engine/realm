module realm.engine.graphics.core;
import gl3n.linalg;
import gl3n.math;
import std.format;
import std.meta;
import std.traits;
import realm.engine.logging;
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
alias BaseImageFormat = GBaseImageFormat;
alias Shader = GShader;
alias SamplerObject = GSamplerObject;
alias QueryObject = GQueryObject;
alias State = GState;
alias FrameBuffer = GFrameBuffer;
alias FrameBufferAttachment = GFrameBufferAttachment;
alias PixelBuffer = GPixelBuffer;
alias ShaderStorage = GShaderStorage;
alias ShaderBlock = GShaderBlock;
alias VertexArrayObject = GVertexArrayObject;
alias VertexBuffer = GVertexBuffer;
alias ElementBuffer = GElementBuffer;
alias UniformBuffer = GUniformBuffer;
alias DrawIndirectCommandBuffer = GDrawIndirectCommandBuffer;
alias DrawElementsIndirectCommand= GDrawElementsIndirectCommand;
alias DepthFunc = GDepthFunc;
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
alias ShaderParameter = GShaderParameter;
alias SizedImageFormat = GSizedImageFormat;
alias CubemapFace = GCubemapFace;
alias BufferUsage = GBufferUsage;
alias BufferStorageMode = GBufferStorageMode;
alias blendFunc = gBlendFunc;
alias blendFuncSeperate = gBlendFuncSeperate;
alias enable =gEnable;
alias disable =gDisable;
alias clear = gClear;
alias cull = gCull;
alias setViewport = gSetViewport;
alias readBuffer = gReadBuffer;
alias setDepthFunc = gSetDepthFunc;
alias setClearColor = gClearColor;
alias enableDebugging = gEnableDebugging;

alias drawBuffers = gDrawBuffers;

alias StandardShaderModel = ShaderProgramModel!(ShaderType.VERTEX,ShaderType.FRAGMENT);
alias ComputeShader = ShaderProgramModel!(ShaderType.COMPUTE);
alias CubemapFaces = AliasSeq!(EnumMembers!GCubemapFace);
enum CubemapFaceIndex(GCubemapFace face ) = 5-(GCubemapFace.NEGATIVE_Z - face);

/// Used to encode information about data types for vertex layout
enum VertexType : int
{
	FLOAT = 0x4011,
	FLOAT2 = 0x4021,
	FLOAT3 = 0x4031,
	FLOAT4 = 0x4041,
	INTEGER = 0x4012
}

/// Types allowed for use per object data in shader
enum UserDataVarTypes : int
{
	VECTOR = VertexType.FLOAT4,
	MATRIX = 0x4101,
	FLOAT = VertexType.FLOAT,
	TEXTURE2D = 0x101D,
	
}

enum VertexSlot
{
	POSITION,
	NORMAL,
	TANGENT
}



enum MeshTopology : int
{
	TRIANGLE = 3,
	LINES = 2
}

/// How framebuffer data is stored
enum GFrameBufferStorage
{
	FB_TEXTURE,
	FB_RENDERBUFFER
};


/// Base vertex layout struct
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

struct PackedVector
{
	import std.bitmanip;

	mixin(bitfields!(
		uint,"x",11,
		uint, "y",11,
		uint,"z",10
	));

	void opAssign(vec3 vector)
	{
		vector.normalize();
		this.x = cast(uint)floor((vector.x * 0.5f + 0.5f) * (pow(2,11) - 1));
		this.y = cast(uint)floor((vector.y * 0.5f + 0.5f) * (pow(2,11) - 1));
		
		this.z = cast(uint)floor((vector.z * 0.5f + 0.5f) * (pow(2,10) - 1));
		
		
	}

}

struct VertexAtrribute
{
	bool normalize;
	bool packed;
	
}





struct TextureDesc
{
	ImageFormat fmt;

	TextureFilterfunc filter = TextureFilterfunc.LINEAR;
	TextureWrapFunc wrap = TextureWrapFunc.CLAMP_TO_BORDER;
	int mipLevels = 0;
	bool isMultisampled = false;
}

class Skybox
{	
	
	enum FaceType
	{
		Cubemap,
		Colored,
		Equirectangular
	}
	
	private FaceType faceType = FaceType.Cubemap;

	union
	{
		IFImage[6] faceTextures;
		vec4[6] faceColors;
		IFImage equirectImage;
	}

	this()
	{
		faceType = FaceType.Cubemap;
	}

	this(vec4 color)
	{
		faceType = FaceType.Colored;
		static foreach(face; CubemapFaces)
		{
			faceColors[CubemapFaceIndex!(face)] = color;
		}
	}

	const FaceType getFaceType()
	{
		return faceType;
	}
	void setFace(CubemapFace Face)(ref IFImage image)
	{
		faceTextures[CubemapFaceIndex!(Face)] = image;
	}

	void freeFaces()
	{
		foreach(img; faceTextures)
		{
			img.free();
		}
	}


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


struct ImageFormatData
{
	BaseImageFormat baseFormat;
	SizedImageFormat sizedFormat;
	uint channels;
	uint bpc;


}


enum ImageFormat : ImageFormatData
{
	RGBA8 = ImageFormatData(BaseImageFormat.RGBA,SizedImageFormat.RGBA8,4,8),
	RGB8 = ImageFormatData(BaseImageFormat.RGB, SizedImageFormat.RGB8,3,8),
	DEPTH = ImageFormatData(BaseImageFormat.DEPTH,SizedImageFormat.DEPTH,1,8),
	DEPTH_STENCIL = ImageFormatData(BaseImageFormat.DEPTH_STENCIL,SizedImageFormat.DEPTH_STENCIL,2,32),
	RED8 = ImageFormatData(BaseImageFormat.RED,SizedImageFormat.RED8,1,8),
	RGBA32F = ImageFormatData(BaseImageFormat.RGBA,SizedImageFormat.RGBA32F,4,32),
	RGBA16 = ImageFormatData(BaseImageFormat.RGBA,SizedImageFormat.RGBA16,4,16),
	RED32F = ImageFormatData(BaseImageFormat.RED,SizedImageFormat.RED32F,1,32),
	RGB32F = ImageFormatData(BaseImageFormat.RGB,SizedImageFormat.RGB32F,3,32),
	SRGB8 = ImageFormatData(BaseImageFormat.RGB,SizedImageFormat.SRGB8,3,8),
	SRGBA8 = ImageFormatData(BaseImageFormat.RGBA,SizedImageFormat.SRGBA8,4,8)

}




/// Raw data structure holding global data for use by all shaders
struct RealmGlobalData
{
	
	float[16] viewMatrix;
	float[16] projectionMatrix;

	//float[16] vp;
	//float[4] mainLightDirection;
	//float[4] mainLightColor;
	//float[16] lightSpaceMatrix;
	//float[4] camPosition;
	//float[4] camDirection;
	//float nearPlane;
	//float farPlane;
	//float[2] size;
  
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


