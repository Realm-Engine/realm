module realm.terraingeneration;

import realm.engine.graphics.core;
import realm.engine.asset;
import std.file : readText;
import realm.engine.logging;

class TerrainGeneration
{
	private ComputeShader _heightMapProgram;

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

	}
}

