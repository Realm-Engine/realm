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
alias WorldMaterialLayout = Alias!(["heightMap" : UserDataVarTypes.TEXTURE2D,"heightStrength" : UserDataVarTypes.FLOAT,"oceanLevel" : UserDataVarTypes.FLOAT]);
alias WorldMaterial = Alias!(Material!WorldMaterialLayout);

class World
{
	private Mesh meshData;
	mixin RealmEntity!(Transform);
	static vec3[] squarePositions;
	static vec2[] squareUV;
	//static uint[] faces;
	static IFImage heightImg;
	WorldMaterial material;
	ShaderProgram shaderProgram;
	this()
	{
		transform = new Transform;
		
		
		//mesh.calculateNormals();
		WorldMaterial.initialze();
		WorldMaterial.reserve(1);
		//generateCube(8);
		meshData = generateFace(vec3(0,-1,0),20);
		transform.position = vec3(0,0,0);
		transform.scale = vec3(2,1,2);
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

	void generateCube(int res)
	{
		vec3[] faceNormals = [vec3(0,1,0),vec3(0,-1,0),vec3(-1,0,0),vec3(1,0,0),vec3(0,0,1),vec3(0,0,-1)];
		Mesh cube;
		foreach(i,normal;enumerate(faceNormals,0))
		{
			Mesh face = generateFace(normal,res);

			cube.positions ~= face.positions;
			cube.normals ~= face.normals;
			cube.textureCoordinates ~= face.textureCoordinates;

			foreach(idx; face.faces)
			{
				cube.faces ~= idx  + ((res*res) * i) ;
			}
		}

		vec2 pointToCoord(vec3 point)
		{
			float latitude = asin(point.y);
			float longitude = atan2(point.x, - point.z);
			return vec2(latitude,longitude);
		}

		foreach(i,pos;cube.positions)
		{
			(&cube.positions[i]).normalize();
			
		}
		meshData = cube;
		//meshData.calculateNormals();

	}

	
	
	Mesh generateFace(vec3 normal, int resolution)
	{
		vec3 axisA = vec3(normal.y,normal.z,normal.x);
		vec3 axisB = normal.cross(axisA);
		vec3[] vertices = new vec3[](resolution * resolution);
		uint[] faces = new uint[]((resolution - 1) * (resolution - 1)  * 6);
		vec2[] uv = new vec2[](resolution * resolution);
		int triIndex = 0;
		for(int y = 0; y < resolution;y++)
		{
			for(int x = 0; x < resolution; x++)
			{
				int vertexIndex = x + y * resolution;
				vec2 t = vec2(x,y) / (resolution - 1.0f);
				vec3 point = normal + axisA * (2 * t.x -1) + axisB * (2 * t.y - 1);
				vertices[vertexIndex] = point;
				uv[vertexIndex] = t;
				if(x != resolution -1 && y != resolution - 1)
				{
					faces[triIndex + 0] = vertexIndex;
					faces[triIndex + 1] = vertexIndex + resolution + 1;
					faces[triIndex + 2] = vertexIndex + resolution;
					faces[triIndex + 3] = vertexIndex;
					faces[triIndex + 4] = vertexIndex + 1;
					faces[triIndex + 5] = vertexIndex + resolution + 1;
					triIndex +=6;
				}
			}
		}
		Mesh mesh;
		mesh.positions = vertices;
		mesh.textureCoordinates = uv;
		mesh.faces = faces;
		mesh.normals = new vec3[](mesh.positions.length);
		mesh.normals[0..$] = normal;
		return mesh;
		
	}

	void draw(Renderer renderer)
	{
		vec3[6] faceNormals = [vec3(0,1,0),vec3(0,-1,0),vec3(-1,0,0),vec3(1,0,0),vec3(0,0,1),vec3(0,0,-1)];
		
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

