module realm.terraingeneration;

import realm.engine.graphics.core;
import realm.engine.asset;
import std.file : readText;
import realm.engine.logging;
import realm.engine.ui.realmui;
import realm.engine.core;
import std.conv;
import realm.engine.app;
class TerrainGeneration
{
	private ComputeShader _stage1Program;
	private ComputeShader _stage2Program;
	private SamplerObject!(TextureType.TEXTURE2D) _heightMap;
	private SamplerObject!(TextureType.TEXTURE2D) _normalMap;
	private SamplerObject!(TextureType.TEXTURE2D) _terrainMap;
	//private RealmUI.UIElement outputPanel;

	private IFImage normalMapImage;
	private IFImage terrainMapImage;
	int seed;


	private Texture2D texture;

	ComputeShader loadComputeShader(string path, string name)
	{
		string src = readText(VirtualFS.getSystemPath(path));
		Shader shader = new Shader(ShaderType.COMPUTE,src,name);
		ComputeShader program = new ComputeShader(name);
		program.computeShader = shader;
		program.compile();
		return program;
	}



	this()
	{
		
		_stage1Program = loadComputeShader("$Assets/Shaders/stage1.glsl","Height map compute shader");
		_stage2Program=   loadComputeShader("$Assets/Shaders/stage2.glsl","Normal map compute shader");
		_heightMap.create();
		_heightMap.textureDesc = TextureDesc(ImageFormat.RGBA8,TextureFilterfunc.LINEAR,TextureWrapFunc.CLAMP_TO_EDGE,0);
		_heightMap.store(2048,2048);
		_normalMap.create();
		_normalMap.textureDesc = TextureDesc(ImageFormat.RGBA8,TextureFilterfunc.LINEAR,TextureWrapFunc.CLAMP_TO_EDGE,0);
		_normalMap.store(2048,2048);
		_terrainMap.create();
		_terrainMap.textureDesc = TextureDesc(ImageFormat.RGBA8,TextureFilterfunc.LINEAR,TextureWrapFunc.CLAMP_TO_EDGE,0);
		_terrainMap.store(2048,2048);
		
		//heightMapImage.free();

		
		

	}

	void stage1(float oceanLevel, float heightStrength)
	{
		this.seed = seed;
	
		Logger.LogInfo("Generating height map...");
		_stage1Program.bindImageWrite(&_heightMap,0,0);
		_stage1Program.bindImageWrite(&_terrainMap,0,1);
		_stage1Program.use();
		_stage1Program.setUniformFloat(0,RealmApp.getTicks);
		_stage1Program.setUniformFloat(1,oceanLevel);
		_stage1Program.setUniformFloat(2,heightStrength);
		_stage1Program.waitImageWriteComplete();
		_stage1Program.dispatch(_heightMap.width,_heightMap.height,1);
		_stage1Program.unbind();

		ubyte[] cellData = _terrainMap.readPixels(0);
		terrainMapImage.buf8.length = cellData.length;
		terrainMapImage.buf8 = cellData;

		terrainMapImage.w = _terrainMap.width;
		terrainMapImage.h = _terrainMap.height;
		terrainMapImage.c = 4;
		terrainMapImage.bpc = 8;
		
	}

	IFImage* generateMap(float oceanLevel, float heightStrength)
	{
		

		stage1( oceanLevel,  heightStrength);


		Logger.LogInfo("Generating normal map...");
		computeJob(&_normalMap,&_heightMap,_stage2Program);
		ubyte[] normalData = _normalMap.readPixels(0);
		normalMapImage.buf8.length = normalData.length;
		normalMapImage.buf8 = normalData;

		normalMapImage.w = _normalMap.width;
		normalMapImage.h = _normalMap.height;
		normalMapImage.c = 4;
		normalMapImage.bpc = 8;

		_heightMap.free();
		_normalMap.free();
		_terrainMap.free();
		return &normalMapImage;
	}


	IFImage* getNormalMap()
	{
		return &normalMapImage;
	}

	IFImage* getTerrainMap()
	{
		return &terrainMapImage;
	}


	void computeJob(Args...)(SamplerObject!(TextureType.TEXTURE2D)* output, ComputeShader shader,Args args)
	{
		import std.traits;
		shader.bindImageWrite(output,0,0);
		shader.use();

		shader.setUniformFloat(0,RealmApp.getTicks);
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

}

