module realm.world;
import realm.engine.core;
import realm.engine.graphics.core;
import realm.engine.graphics.material;
import realm.engine.graphics.renderer;
import std.file : read;
import core.math;
import std.range;
import gl3n.math : asin, atan2;
import std.stdio;
import realm.ocean;
import realm.util;
import realm.entitymanager;
alias WorldMaterialLayout = Alias!(["heightMap" : UserDataVarTypes.TEXTURE2D,
									"heightMap2" : UserDataVarTypes.TEXTURE2D,
									"heightStrength" : UserDataVarTypes.FLOAT,
									"oceanLevel" : UserDataVarTypes.FLOAT]);
alias WorldMaterial = Alias!(Material!WorldMaterialLayout);

class World
{
	private Mesh meshData;

	mixin RealmEntity!("World",Transform);

	static vec3[] squarePositions;
	static vec2[] squareUV;
	//static uint[] faces;
	private IFImage heightImg;
	private IFImage heightImg2;
	WorldMaterial material;
	private Transform transform;
	private Ocean ocean;
	ShaderProgram shaderProgram;



	void start(EntityManager manager)
	{
		WorldMaterial.initialze();
		WorldMaterial.reserve(1);
		heightImg = readImageBytes("$Assets/Images/noiseTexture1.png");
		heightImg2 = readImageBytes("$Assets/Images/noiseTexture2.png");
		//setComponent!(Transform)(new Transform);
		transform = getComponent!(Transform);
		material = new WorldMaterial;
                



		meshData = generateFace(vec3(0,1,0),20);
		WorldMaterial.allocate(&meshData);
		transform.position = vec3(0,-2,0);
		transform.scale = vec3(20,1,15);
		shaderProgram = loadShaderProgram("$Assets/Shaders/world.shader","World");
		
		material.heightStrength = 1.5;
		material.oceanLevel = 0.7;
		material.setShaderProgram(shaderProgram);
		material.textures.heightMap = new Texture2D(&heightImg);
		material.textures.heightMap2 = new Texture2D(&heightImg2);
		material.textures.settings = TextureDesc(ImageFormat.RGBA8,TextureFilterfunc.LINEAR,TextureWrapFunc.CLAMP_TO_BORDER);
		material.packTextureAtlas();
		
		ocean = manager.instantiate!(Ocean)(material.oceanLevel,material.textures.heightMap.texture,material.heightStrength);
		ocean.getComponent!(Transform).scale = getComponent!(Transform).scale;

		

		scope(exit)
		{

			heightImg.free();
		}

	}
	static this()
	{
		squarePositions = [vec3(-0.5f,-0.5f,0),vec3(0.5,-0.5f,0),vec3(0.5,0.5f,0),vec3(-0.5,0.5f,0.0f)];
		squareUV = [vec2(0,0),vec2(1,0),vec2(1,1),vec2(0,1)];
		

	}

	

	void draw(Renderer renderer)
	{

		renderer.submitMesh!(WorldMaterial,true)(meshData,transform,material);
		ocean.draw(renderer);
	}

	void update()
	{
		

		
	}
}

