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
	static IFImage heightImg;
	WorldMaterial material;
	private Transform transform;
	private Ocean ocean;
	ShaderProgram shaderProgram;
   

	this(EntityManager manager)
	{
		heightImg = readImageBytes("$Assets/Images/noiseTexture.png");
		setComponent!(Transform)(new Transform);
		transform = getComponent!(Transform);
		
                

		WorldMaterial.initialze();
		WorldMaterial.reserve(1);

		meshData = generateFace(vec3(0,1,0),24);
		WorldMaterial.allocate(&meshData);
		transform.position = vec3(0,-2,0);
		transform.scale = vec3(5,1,3.5);
		shaderProgram = loadShaderProgram("$Assets/Shaders/world.shader","World");
		material = new WorldMaterial;
		material.heightStrength = 0.5;
		material.oceanLevel = 0.225;
		material.setShaderProgram(shaderProgram);
		material.textures.heightMap = new Texture2D(&heightImg);
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
		renderer.submitMesh!(WorldMaterial)(meshData,transform,material);
		ocean.draw(renderer);
	}

	void update()
	{
		

		
	}
}

