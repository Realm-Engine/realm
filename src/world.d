module realm.world;
import realm.engine.ecs;
import realm.engine.core;
import realm.engine.asset;
import realm.engine.graphics.core;
import realm.engine.graphics.material;
import realm.engine.graphics.renderer;
import std.meta;
import std.file : read;
import core.math;
import std.range;
import realm.engine.logging;
import gl3n.math : asin, atan2;
import std.stdio;
import realm.ocean;
import realm.util;
alias WorldMaterialLayout = Alias!(["heightMap" : UserDataVarTypes.TEXTURE2D,"heightStrength" : UserDataVarTypes.FLOAT,"oceanLevel" : UserDataVarTypes.FLOAT]);
alias WorldMaterial = Alias!(Material!WorldMaterialLayout);

class World
{
	private Mesh meshData;

	mixin RealmEntity!(Transform,Ocean);

	static vec3[] squarePositions;
	static vec2[] squareUV;
	//static uint[] faces;
	static IFImage heightImg;
	WorldMaterial material;

	ShaderProgram shaderProgram;
	
	this()
	{
		transform = new Transform;
		ocean = new Ocean;
		
		//mesh.calculateNormals();
		WorldMaterial.initialze();
		WorldMaterial.reserve(1);
		//generateCube(8);
		meshData = generateFace(vec3(0,-1,0),20);

		transform.position = vec3(0,0,0);
		transform.scale = vec3(5,1,3.5);
		auto vertexShader = read("./Assets/Shaders/vertexShader.glsl");
		auto fragmentShader = read("./Assets/Shaders/fragShader.glsl");
		

		Shader vertex = new Shader(ShaderType.VERTEX,cast(string) vertexShader,"Vetex Shader");
		Shader fragment = new Shader(ShaderType.FRAGMENT,cast(string)fragmentShader,"Fragment Shader");
		shaderProgram = new ShaderProgram(vertex,fragment,"MyProgram");
		material = new WorldMaterial;
		material.heightStrength = 0.25;
		material.oceanLevel = 0.4;
		material.setShaderProgram(shaderProgram);
		material.textures.heightMap = new Texture2D(&heightImg,TextureDesc(ImageFormat.RGBA8,TextureFilterfunc.LINEAR,TextureWrapFunc.CLAMP_TO_BORDER));
		material.textures.settings = TextureDesc(ImageFormat.RGBA8,TextureFilterfunc.LINEAR,TextureWrapFunc.CLAMP_TO_BORDER);
		material.packTextureAtlas();
		

		//material.color = vec4(1.0,1.0,1.0,1.0);
		

		scope(exit)
		{

			heightImg.free();
		}

	}
	static this()
	{
		squarePositions = [vec3(-0.5f,-0.5f,0),vec3(0.5,-0.5f,0),vec3(0.5,0.5f,0),vec3(-0.5,0.5f,0.0f)];
		squareUV = [vec2(0,0),vec2(1,0),vec2(1,1),vec2(0,1)];
		//faces = [0,1,2,2,3,0];
		heightImg = readImageBytes("./Assets/Images/height.png");

	}

	

	void draw(Renderer renderer)
	{
		//vec3[6] faceNormals = [vec3(0,1,0),vec3(0,-1,0),vec3(-1,0,0),vec3(1,0,0),vec3(0,0,1),vec3(0,0,-1)];
		
		
		ocean.draw(renderer);
		renderer.submitMesh!(WorldMaterial)(meshData,transform,material);
		//renderer.submitMesh!(WorldMaterial)(mesh,transform,material);
	}

	void update()
	{
		
		//transform.position += vec3(0,0,0.1);
		//writeln( transform.rotation);
		updateComponents();
	}


}

