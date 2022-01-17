module realm.terraingeneration;

import realm.engine.graphics.core;
import realm.engine.asset;
import std.file : readText;
import realm.engine.logging;

class TerrainGeneration
{
	private ComputeShader _heightMapProgram;
	private SamplerObject!(TextureType.TEXTURE2D) _heightMap;

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
		_heightMap.textureDesc = TextureDesc(ImageFormat.RED32F,TextureFilterfunc.LINEAR,TextureWrapFunc.CLAMP_TO_EDGE,0);
		_heightMap.store(256,256);
		computeJob(&_heightMap,_heightMapProgram);
		

	}

	void computeJob(SamplerObject!(TextureType.TEXTURE2D)* output, ComputeShader shader)
	{
		shader.bindImageWrite(output,0,0);
		shader.use();
		shader.waitImageWriteComplete();
		shader.dispatch(output.width,output.height,1);
		shader.unbind();

	}
}

