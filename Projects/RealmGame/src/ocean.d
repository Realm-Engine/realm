module realm.ocean;
import realm.engine.core;
import realm.engine.graphics.core;
import realm.engine.graphics.material;
import realm.engine.graphics.renderer;
import realm.engine.app;
import std.meta;
import realm.util;
import std.file : read;

alias WaterMaterialLayout = Alias!(["color" : UserDataVarTypes.VECTOR,
									"heightMap" : UserDataVarTypes.TEXTURE2D,
									"oceanLevel" : UserDataVarTypes.FLOAT,
									"heightStrength" : UserDataVarTypes.FLOAT,
									"shallowColor" : UserDataVarTypes.VECTOR,
									"deepColor" : UserDataVarTypes.VECTOR]);
alias WaterMaterial = Alias!(Material!(WaterMaterialLayout, 1));
class Ocean
{

	mixin RealmEntity!("Ocean",Transform,Mesh);
	WaterMaterial material;
	StandardShaderModel shaderProgram;
	private Mesh* mesh;
	private Transform transform;

	void start(float oceanLevel,Texture2D worldHeight,float heightStrength)
	{
		//setComponent!(Transform)(new Transform);
		transform = getComponent!(Transform);
		mesh = &getComponent!(Mesh)();
		WaterMaterial.initialze();
		WaterMaterial.reserve(1);
		
		
		shaderProgram = loadShaderProgram("$Assets/Shaders/water.shader","Water");
		
		material = new WaterMaterial;
		material.color = vec4(0,0,0.7,1.0);
		material.oceanLevel = oceanLevel;
		material.textures.heightMap = worldHeight;
		material.heightStrength = heightStrength;
		material.shallowColor = vec4(20,185,209,1.0);
		material.deepColor = vec4(21,33,209,1.0);
		material.textures.settings = TextureDesc(ImageFormat.RGBA8,TextureFilterfunc.LINEAR,TextureWrapFunc.MIRROR);

		material.setShaderProgram(shaderProgram);
		material.packTextureAtlas();
		
		setComponent!(Mesh)(generateFace(vec3(0,-1,0),10));
		WaterMaterial.allocate(mesh);
		

	}

	static this()
	{

	}

	void update()
	{
		
	}

	void draw(Renderer renderer)
	{
		renderer.submitMesh!(WaterMaterial,true)(*mesh,transform,material);
	}
}