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

	struct GenSettings
	{
		float oceanLevel;
		float heightStrength;
		float iceThreshold;
		float heatStrength;
	}

	mixin RealmEntity!("TerrainGeneration");

	private ComputeShader _stage1Program;
	private ComputeShader _stage2Program;
	private ComputeShader _climateGenProgram;
	private SamplerObject!(TextureType.TEXTURE2D) _heightMap;
	private SamplerObject!(TextureType.TEXTURE2D) _normalMap;
	private SamplerObject!(TextureType.TEXTURE2D) _climateMap;
	private ShaderStorage!(float,BufferUsage.MappedRead) tileData;
	//private RealmUI.UIElement outputPanel;

	private IFImage normalMapImage;
	private IFImage _climateMapImage;
	float seed;
	GenSettings settings;

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



	void start(GenSettings settings)
	{
		this.settings = settings;
		_stage1Program = loadComputeShader("$Assets/Shaders/stage1.glsl","Terrain gen stage 1");
		_stage2Program=   loadComputeShader("$Assets/Shaders/stage2.glsl","Terrain gen stage 2");
		_climateGenProgram = loadComputeShader("$Assets/Shaders/climateGeneration.glsl","Shore distance");

		_heightMap.create();
		_heightMap.textureDesc = TextureDesc(ImageFormat.RGBA8,TextureFilterfunc.LINEAR,TextureWrapFunc.CLAMP_TO_EDGE,0);
		_heightMap.store(2048,2048);
		_normalMap.create();
		_normalMap.textureDesc = TextureDesc(ImageFormat.RGBA8,TextureFilterfunc.LINEAR,TextureWrapFunc.CLAMP_TO_EDGE,0);
		_normalMap.store(2048,2048);
		_climateMap.create();
		_climateMap.textureDesc = TextureDesc(ImageFormat.RGBA8,TextureFilterfunc.LINEAR,TextureWrapFunc.CLAMP_TO_EDGE,0);
		_climateMap.store(2048,2048);
		seed = RealmApp.getTicks();
	}

	void stage1()
	{
		
	
		Logger.LogInfo("Generating height map...");
		_stage1Program.bindImageWrite(&_heightMap,0,0);
		_stage1Program.bindImageWrite(&_climateMap,0,1);
		_stage1Program.use();
		_stage1Program.setUniformFloat(0,seed);
		_stage1Program.setUniformFloat(1,settings.oceanLevel);
		_stage1Program.setUniformFloat(2,settings.heightStrength);
		_stage1Program.setUniformFloat(3,settings.iceThreshold);
		_stage1Program.setUniformFloat(4,settings.heatStrength);
		_stage1Program.waitImageWriteComplete();
		_stage1Program.dispatch(_heightMap.width,_heightMap.height,1);
		_stage1Program.unbind();


		
	}

	void simulateClimate()
	{
		import std.random;
		SamplerObject!(TextureType.TEXTURE2D) _fluxMap;
		_fluxMap.create();
		_fluxMap.textureDesc = TextureDesc(ImageFormat.RED8,TextureFilterfunc.LINEAR,TextureWrapFunc.CLAMP_TO_EDGE,0);
		_fluxMap.store(_climateMap.width,_climateMap.height);
		auto rnd = Random(unpredictableSeed);
		real numSeeds = sqrt(cast(real)_fluxMap.width);
		

		

	
		//
		//_climateGenProgram.use();
		//_climateGenProgram.bindImageWrite(&_climateMap,0,0);
		//_climateGenProgram.bindImageWrite(&_fluxMap,0,1);
		//_climateGenProgram.setUniformFloat(1,seed);
		//_climateGenProgram.setUniformFloat(2,9.81);
		//_climateGenProgram.setUniformFloat(3,settings.heightStrength);
		//int tick = 0;
		//for(tick = 0; tick < 100;tick++)
		//{
		//    //Logger.LogInfo("Distance pass: stepsize: %d",stepSize );
		//    _climateGenProgram.setUniformInt(0,tick);
		//    _climateGenProgram.dispatch(_normalMap.width,_normalMap.height,1);
		//    _climateGenProgram.unbind();
		//    _climateGenProgram.waitImageWriteComplete();
		//}
		


	}

	void stage2()
	{
		tileData.create();
		tileData.bind();
		tileData.store(1);


		_stage2Program.bindImageWrite(&_normalMap,0,0);
		_stage2Program.bindImageWrite(&_heightMap,0,1);
		_stage2Program.bindImageWrite(&_climateMap,0,2);
		_stage2Program.use();
		tileData.bindBase(3);
		_stage2Program.setUniformFloat(0,settings.heightStrength);
		_stage2Program.dispatch(_normalMap.width,_normalMap.height,1);
		_stage2Program.waitImageWriteComplete();
		_stage2Program.unbind();

		tileData.unbind();
		tileData.refreshPointer();
		float* tiles = tileData.ptr;
		Logger.LogInfo("%f",tiles[0]);

		

		simulateClimate();

		



		ubyte[] normalData = _normalMap.readPixels(0);
		normalMapImage.buf8.length = normalData.length;
		normalMapImage.buf8 = normalData;

		normalMapImage.w = _normalMap.width;
		normalMapImage.h = _normalMap.height;
		normalMapImage.c = 4;
		normalMapImage.bpc = 8;

		ubyte[] cellData = _climateMap.readPixels(0);
		_climateMapImage.buf8.length = cellData.length;
		_climateMapImage.buf8 = cellData;

		_climateMapImage.w = _climateMap.width;
		_climateMapImage.h = _climateMap.height;
		_climateMapImage.c = 4;
		_climateMapImage.bpc = 8;
	}


	void update()
	{

	}

	void generateMap()
	{
		

		stage1();


		Logger.LogInfo("Generating normal map...");
		stage2();
		

		_heightMap.free();
		_normalMap.free();
		_climateMap.free();
		//writeImageBytes(&normalMapImage,"$Assets/test.png");
		
	}


	IFImage* getNormalMap()
	{
		return &normalMapImage;
	}

	IFImage* getClimateMap()
	{
		return &_climateMapImage;
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

