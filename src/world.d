module realm.world;
import realm.engine.ecs;
import realm.engine.core;
import realm.engine.asset;
import realm.engine.graphics.core;
import realm.engine.graphics.material;
import realm.engine.graphics.renderer;
import std.meta;
import std.file : read;
alias WorldMaterialLayout = Alias!(["color":UserDataVarTypes.VECTOR,"albedo" : UserDataVarTypes.TEXTURE2D]);
alias WorldMaterial = Alias!(Material!WorldMaterialLayout);

class World
{
	mixin RealmEntity!(Transform,Mesh);
	static vec3[] squarePositions;
	static vec2[] squareUV;
	static uint[] faces;
	static IFImage grassImg;
	WorldMaterial material;
	ShaderProgram shaderProgram;
	this()
	{
		transform = new Transform;
		
		mesh.positions = squarePositions;
		mesh.textureCoordinates =  squareUV;
		mesh.faces = faces;
		mesh.calculateNormals();
		WorldMaterial.initialze();
		WorldMaterial.reserve(1);
		auto vertexShader = read("./Assets/Shaders/vertexShader.glsl");
		auto fragmentShader = read("./Assets/Shaders/fragShader.glsl");
		Shader vertex = new Shader(ShaderType.VERTEX,cast(string) vertexShader,"Vetex Shader");
		Shader fragment = new Shader(ShaderType.FRAGMENT,cast(string)fragmentShader,"Fragment Shader");
		shaderProgram = new ShaderProgram(vertex,fragment,"MyProgram");
		material = new WorldMaterial;
		material.setShaderProgram(shaderProgram);
		material.textures.albedo = new Texture2D(&grassImg,TextureDesc(ImageFormat.RGBA8,TextureFilterfunc.LINEAR,TextureWrapFunc.CLAMP_TO_BORDER));
		material.textures.settings = TextureDesc(ImageFormat.RGBA8,TextureFilterfunc.LINEAR,TextureWrapFunc.CLAMP_TO_BORDER);
		material.packTextureAtlas();
		material.color = vec4(1.0,1.0,1.0,1.0);
		

		scope(exit)
		{
			grassImg.free();
		}

	}
	static this()
	{
		squarePositions = [vec3(-0.5f,-0.5f,0),vec3(0.5,-0.5f,0),vec3(0.5,0.5f,0),vec3(-0.5,0.5f,0.0f)];
		squareUV = [vec2(0,0),vec2(1,0),vec2(1,1),vec2(0,1)];
		faces = [0,1,2,2,3,0];
		grassImg = readImageBytes("./Assets/Images/grass.png");

	}

	void draw(Renderer renderer)
	{
		
		renderer.submitMesh!(WorldMaterial)(mesh,transform,material);
	}

	void update()
	{
		updateComponents();
	}


}

