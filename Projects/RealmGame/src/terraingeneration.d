module realm.terraingeneration;

import realm.engine.graphics.core;
import realm.engine.asset;
import std.file : readText;
import realm.engine.logging;
import realm.engine.ui.realmui;
import realm.engine.core;
import std.conv;
class TerrainGeneration
{
	private ComputeShader _heightMapProgram;
	private ComputeShader _normalMapProgram;
	private SamplerObject!(TextureType.TEXTURE2D) _heightMap;
	private SamplerObject!(TextureType.TEXTURE2D) _normalMap;
	//private RealmUI.UIElement outputPanel;
	private IFImage heightMapImage;
	private IFImage normalMapImage;
	private Texture2D texture;
	this()
	{
		
		string heightMapShaderSrc = readText(VirtualFS.getSystemPath("$Assets/Shaders/terrainHeight.glsl"));
		string normalMapShaderSrc = readText(VirtualFS.getSystemPath("$Assets/Shaders/terrainNormal.glsl"));
		Shader heightMapShader = new Shader(ShaderType.COMPUTE,heightMapShaderSrc,"Height map compute shader");
		Shader normalMapShader=  new Shader(ShaderType.COMPUTE,normalMapShaderSrc,"Normal map compute shader");
		_heightMapProgram = new ComputeShader("Height map");
		_normalMapProgram = new ComputeShader("Normal map");
		_heightMapProgram.computeShader = heightMapShader;
		_heightMapProgram.compile();
		_normalMapProgram.computeShader = normalMapShader;
		_normalMapProgram.compile();
		int[3] workGroupCount;
		workGroupCount[0] = _heightMapProgram.getParameter!(int)(ShaderParameter.COMPUTE_WORK_GROUP_COUNT,0);
		workGroupCount[1] = _heightMapProgram.getParameter!(int)(ShaderParameter.COMPUTE_WORK_GROUP_COUNT,1);
		workGroupCount[2] = _heightMapProgram.getParameter!(int)(ShaderParameter.COMPUTE_WORK_GROUP_COUNT,2);
		Logger.LogInfo("Max compute work counts: X: %d, Y: %d, Z: %d",workGroupCount[0],workGroupCount[1],workGroupCount[2]);
		_heightMap.create();
		_heightMap.textureDesc = TextureDesc(ImageFormat.RGBA8,TextureFilterfunc.LINEAR,TextureWrapFunc.CLAMP_TO_EDGE,0);
		_heightMap.store(2048,2048);
		_normalMap.create();
		_normalMap.textureDesc = TextureDesc(ImageFormat.RGBA8,TextureFilterfunc.LINEAR,TextureWrapFunc.CLAMP_TO_EDGE,0);
		_normalMap.store(2048,2048);
		computeJob(&_heightMap,_heightMapProgram);
		
		ubyte[] heightData = _heightMap.readPixels(0);
		
		heightMapImage.buf8.length = heightData.length ;

		heightMapImage.buf8 = heightData;

		heightMapImage.w = _heightMap.width;
		heightMapImage.h = _heightMap.height;
		heightMapImage.c = 4;
		heightMapImage.bpc = 8;
		computeJob(&_normalMap,&_heightMap,_normalMapProgram);
		ubyte[] normalData = _normalMap.readPixels(0);
		normalMapImage.buf8.length = normalData.length;
		normalMapImage.buf8 = normalData;
		
		normalMapImage.w = _normalMap.width;
		normalMapImage.h = _normalMap.height;
		normalMapImage.c = 4;
		normalMapImage.bpc = 8;
		


		
		

	}

	IFImage* getHeightMap()
	{
		return &heightMapImage;
	}

	IFImage* getNormalMap()
	{
		return &normalMapImage;
	}


	void computeJob(SamplerObject!(TextureType.TEXTURE2D)* output, ComputeShader shader)
	{
		shader.bindImageWrite(output,0,0);
		shader.use();
		shader.waitImageWriteComplete();
		shader.dispatch(output.width,output.height,1);
		shader.unbind();

	}
	void computeJob(SamplerObject!(TextureType.TEXTURE2D)* output,SamplerObject!(TextureType.TEXTURE2D)* input, ComputeShader shader)
	in(input.width == output.width,"Input and output need to be same size")
	in(input.height == output.height,"Input and output need to be same size")
	{
		shader.bindImageWrite(output,0,0);
		shader.bindImageWrite(input,0,1);
		shader.use();
		shader.waitImageWriteComplete();
		shader.dispatch(output.width,output.height,1);
		shader.unbind();

	}

	void componentUpdate()
	{
		//RealmUI.drawPanel(outputPanel,vec4(1));
	}
	void freeTextures()
	{
		heightMapImage.free();

	}
}

