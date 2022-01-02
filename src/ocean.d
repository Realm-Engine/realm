module realm.ocean;
import realm.engine.core;
import realm.engine.graphics.core;
import realm.engine.graphics.material;
import realm.engine.graphics.renderer;
import std.meta;
import realm.util;
import std.file : read;
alias WaterMaterialLayout = Alias!(["color" : UserDataVarTypes.VECTOR, "depthTexture" : UserDataVarTypes.DEPTHTEXTURE,"oceanLevel" : UserDataVarTypes.FLOAT]);
alias WaterMaterial = Alias!(Material!(WaterMaterialLayout, 1));
class Ocean
{

	mixin RealmEntity!(Transform,Mesh);
	WaterMaterial material;
	ShaderProgram shaderProgram;
	this(float oceanLevel)
	{
		transform = new Transform;
		WaterMaterial.initialze();
		WaterMaterial.reserve(1);

		
		shaderProgram = loadShaderProgram("Assets/Shaders/water.shader","Water");
		
		material = new WaterMaterial;
		material.color = vec4(0,0,0.7,1.0);
		material.oceanLevel = oceanLevel;
		material.textures.depthTexture = Renderer.getMainFrameBuffer();
		material.setShaderProgram(shaderProgram);
		material.packTextureAtlas();
		
		mesh = generateFace(vec3(0,-1,0),10);
		

	}

	void draw(Renderer renderer)
	{
		renderer.submitMesh!(WaterMaterial)(mesh,transform,material);
	}

	void componentUpdate()
	{
		updateComponents();
	}
}