module realm.ocean;
import realm.engine.ecs;
import realm.engine.core;
import realm.engine.asset;
import realm.engine.graphics.core;
import realm.engine.graphics.material;
import realm.engine.graphics.renderer;
import std.meta;
import realm.util;
import std.file : read;
alias WaterMaterialLayout = Alias!(["color" : UserDataVarTypes.VECTOR, "oceanLevel" : UserDataVarTypes.FLOAT]);
alias WaterMaterial = Alias!(Material!WaterMaterialLayout);
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

		auto waterVertexShader = read("Assets/Shaders/waterVertex.glsl");
		auto waterFragmentShader = read("Assets/Shaders/waterFrag.glsl");
		Shader waterVertex = new Shader(ShaderType.VERTEX,cast(string)waterVertexShader,"Water vertex");
		Shader waterFragment = new Shader(ShaderType.FRAGMENT,cast(string)waterFragmentShader,"Water fragment");
		
		shaderProgram = new ShaderProgram(waterVertex,waterFragment,"MyProgram");
		
		material = new WaterMaterial;
		material.color = vec4(0,0,0.7,1.0);
		material.oceanLevel = oceanLevel;
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