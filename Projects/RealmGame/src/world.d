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
import realm.terraingeneration;
alias WorldMaterialLayout = Alias!(["normalHeightMap" : UserDataVarTypes.TEXTURE2D,
									"terrainDataMap" : UserDataVarTypes.TEXTURE2D,
									"heightStrength" : UserDataVarTypes.FLOAT,
									"oceanLevel" : UserDataVarTypes.FLOAT]);
alias WorldMaterial = Alias!(Material!WorldMaterialLayout);

class World
{
	private Mesh meshData;

	mixin RealmEntity!("World",Transform,TerrainGeneration);

	static vec3[] squarePositions;
	static vec2[] squareUV;
	//static uint[] faces;
	private IFImage heightNormalMap;

	WorldMaterial material;
	private Transform transform;
	private Ocean ocean;
	StandardShaderModel shaderProgram;
	private int seed;


	void start(EntityManager manager)
	{

		WorldMaterial.initialze();
		WorldMaterial.reserve(1);
		//setComponent!(Transform)(new Transform);
		transform = getComponent!(Transform);
		material = new WorldMaterial;
		this.seed = seed;


		meshData = generateFace(vec3(0,1,0),20);
		WorldMaterial.allocate(&meshData);
		transform.position = vec3(0,0,0);
		transform.scale = vec3(700,1,700 *0.7) ;
		shaderProgram = loadShaderProgram("$Assets/Shaders/world.shader","World");
		
		material.heightStrength = 50;
		material.oceanLevel =10;
		material.setShaderProgram(shaderProgram);
		//material.textures.heightMap = new Texture2D(getComponent!(TerrainGeneration).getHeightMap());
		
		material.textures.settings = TextureDesc(ImageFormat.RGBA8,TextureFilterfunc.LINEAR,TextureWrapFunc.CLAMP_TO_BORDER);
		generateWorld();
		
		ocean = manager.instantiate!(Ocean)(material.oceanLevel,material.textures.normalHeightMap.texture,material.heightStrength);
		ocean.getComponent!(Transform).scale = getComponent!(Transform).scale;
		//ocean.getComponent!(Transform).position = transform.position;
		

		scope(exit)
		{
			
		}

	}
	static this()
	{
		squarePositions = [vec3(-0.5f,-0.5f,0),vec3(0.5,-0.5f,0),vec3(0.5,0.5f,0),vec3(-0.5,0.5f,0.0f)];
		squareUV = [vec2(0,0),vec2(1,0),vec2(1,1),vec2(0,1)];
		

	}

	void generateWorld()
	{
		material.textures.normalHeightMap = new Texture2D(getComponent!(TerrainGeneration).generateMap(material.oceanLevel,material.heightStrength));
		material.textures.terrainDataMap = new Texture2D(getComponent!(TerrainGeneration).getTerrainMap());
		material.packTextureAtlas();
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

