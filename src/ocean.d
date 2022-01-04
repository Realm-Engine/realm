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
									"deepColor" : UserDataVarTypes.VECTOR,
									"noise1" : UserDataVarTypes.TEXTURE2D,
									"noise2" : UserDataVarTypes.TEXTURE2D,
									"time" : UserDataVarTypes.FLOAT,
									"scrollSpeed" : UserDataVarTypes.FLOAT,
									"distortion" : UserDataVarTypes.TEXTURE2D]);
alias WaterMaterial = Alias!(Material!(WaterMaterialLayout, 1));
class Ocean
{

	mixin RealmEntity!(Transform,Mesh);
	WaterMaterial material;
	ShaderProgram shaderProgram;
	private static IFImage noise1;
	private static IFImage noise2;
	private static IFImage distortionMap;
	this(float oceanLevel,Texture2D worldHeight,float heightStrength)
	{
		transform = new Transform;
		WaterMaterial.initialze();
		WaterMaterial.reserve(1);

		
		shaderProgram = loadShaderProgram("Assets/Shaders/water.shader","Water");
		
		material = new WaterMaterial;
		material.color = vec4(0,0,0.7,1.0);
		material.oceanLevel = oceanLevel;
		material.textures.heightMap = worldHeight;
		material.heightStrength = heightStrength;
		material.shallowColor = vec4(20,185,209,1.0);
		material.deepColor = vec4(21,33,209,1.0);
		material.textures.settings = TextureDesc(ImageFormat.RGBA8,TextureFilterfunc.LINEAR,TextureWrapFunc.MIRROR);
		material.textures.noise1 = new Texture2D(&noise1,material.textures.settings);
		material.textures.noise2 = new Texture2D(&noise2,material.textures.settings);
		material.textures.distortion = new Texture2D(&distortionMap,material.textures.settings);
		material.scrollSpeed = 200;
		material.setShaderProgram(shaderProgram);
		material.packTextureAtlas();
		
		mesh = generateFace(vec3(0,-1,0),10);

		scope(exit)
		{
			noise1.free();
			noise2.free();
			distortionMap.free();
		}
		

	}

	static this()
	{
		noise1 = readImageBytes("./Assets/Images/water/noise.png");
		noise2 = readImageBytes("./Assets/Images/water/noise2.png");
		distortionMap = readImageBytes("./Assets/Images/water/distortion_map.png");
	}

	void draw(Renderer renderer)
	{
		renderer.submitMesh!(WaterMaterial)(mesh,transform,material);
	}

	void componentUpdate()
	{
		material.time = RealmApp.getTicks();
		updateComponents();
	}
}