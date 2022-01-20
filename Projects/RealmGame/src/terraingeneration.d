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
	private SamplerObject!(TextureType.TEXTURE2D) _heightMap;
	private RealmUI.UIElement outputPanel;
	private IFImage heightMapImage;
	private Texture2D texture;
	this()
	{
		
		string heightMapShaderSrc = readText(VirtualFS.getSystemPath("$Assets/Shaders/terrainHeight.glsl"));
		Shader heightMapShader = new Shader(ShaderType.COMPUTE,heightMapShaderSrc,"Height map compute shader");
		_heightMapProgram = new ComputeShader("Height map");
		_heightMapProgram.computeShader = heightMapShader;
		_heightMapProgram.compile();
		int[3] workGroupCount;
		workGroupCount[0] = _heightMapProgram.getParameter!(int)(ShaderParameter.COMPUTE_WORK_GROUP_COUNT,0);
		workGroupCount[1] = _heightMapProgram.getParameter!(int)(ShaderParameter.COMPUTE_WORK_GROUP_COUNT,1);
		workGroupCount[2] = _heightMapProgram.getParameter!(int)(ShaderParameter.COMPUTE_WORK_GROUP_COUNT,2);
		Logger.LogInfo("Max compute work counts: X: %d, Y: %d, Z: %d",workGroupCount[0],workGroupCount[1],workGroupCount[2]);
		_heightMap.create();
		_heightMap.textureDesc = TextureDesc(ImageFormat.RGBA8,TextureFilterfunc.LINEAR,TextureWrapFunc.CLAMP_TO_EDGE,0);
		_heightMap.store(2048,2048);
		computeJob(&_heightMap,_heightMapProgram);
		ubyte[] heightData = _heightMap.readPixels(0);
		
		heightMapImage.buf8.length = heightData.length ;

		heightMapImage.buf8 = heightData.dup;

		heightMapImage.w = _heightMap.width;
		heightMapImage.h = _heightMap.height;
		heightMapImage.c = 1;
		heightMapImage.bpc = 32;
		texture = new Texture2D(&heightMapImage);
		outputPanel = RealmUI.createElement(vec3(600,300,0),vec3(256,256,1),vec3(0),texture,TextureDesc(ImageFormat.RGBA8,TextureFilterfunc.LINEAR,TextureWrapFunc.CLAMP_TO_EDGE,0));
		

	}

	IFImage* getHeightMap()
	{
		return &heightMapImage;
	}



	void computeJob(SamplerObject!(TextureType.TEXTURE2D)* output, ComputeShader shader)
	{
		shader.bindImageWrite(output,0,0);
		shader.use();
		shader.waitImageWriteComplete();
		shader.dispatch(output.width,output.height,1);
		shader.unbind();

	}

	void componentUpdate()
	{
		RealmUI.drawPanel(outputPanel,vec4(1));
	}
}

