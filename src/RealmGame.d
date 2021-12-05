module realm.game;
import realm.engine.app;
import std.stdio;
import realm.engine.core;
import gl3n.linalg;
import realm.entity;
import realm.engine.containers.queue;
import realm.engine.graphics.core;
import realm.engine.graphics.graphicssubsystem;
import realm.engine.graphics.renderer;
import std.file : read;
import realm.engine.graphics.material;
import std.meta;
//import realm.engine.graphics.core;
class RealmGame : RealmApp
{

	ShaderProgram program;
	Mesh triangle;
	Camera cam;
	Renderer renderer;

	static Mesh squareMesh;
	Entity!(EntityMaterial) entity;
	alias EntityMaterialLayout =  Alias!(["color":UserDataVarTypes.VECTOR]);
	alias EntityMaterial = Material!(EntityMaterialLayout);
	Entity!(EntityMaterial) floor;
	


	static this()
	{

		


		uint[] faces = [0,1,2,2,3,0];
		vec3[] square = [vec3(-0.5f,-0.5f,0),vec3(0.5,-0.5f,0),vec3(0.5,0.5f,0),vec3(-0.5,0.5f,0.0f)];	
		
		squareMesh.positions = square;
		squareMesh.faces = faces;
		squareMesh.calculateNormals();
		squareMesh.textureCoordinates = [vec2(0,0),vec2(0,0),vec2(0,0),vec2(0,0)];
		squareMesh.calculateNormals();
	
	}




	this(int width, int height, const char* title)
	{
		
		

		super(width,height,title);
		
		renderer = new Renderer;
		cam = new Camera(CameraProjection.PERSPECTIVE,vec2(cast(float)width,cast(float)height),100,-0.1,45);
		auto vertexShader = read("./src/engine/res/vertexShader.glsl");
		auto fragmentShader = read("./src/engine/res/fragShader.glsl");
		Shader vertex = new Shader(ShaderType.VERTEX,cast(string) vertexShader,"Vetex Shader");
		Shader fragment = new Shader(ShaderType.FRAGMENT,cast(string)fragmentShader,"Fragment Shader");
		program = new ShaderProgram(vertex,fragment,"MyProgram");
		EntityMaterial.initialze();
		EntityMaterial.reserve(2);

	}

	override void start()
	{
		
		
		

		Transform transform = new Transform;	
		entity = new Entity!(EntityMaterial)(squareMesh,transform);
		floor = new Entity!(EntityMaterial)(squareMesh);
		floor.eulerRotation(vec3(90,0,0));
		floor.position = vec3(0,-0.2f,0);
		entity.material = new EntityMaterial();
		floor.material = new EntityMaterial();
		entity.material.color = vec4(0.7,0.1,0.5,1.0);
		floor.material.color = vec4(0.8,0.8,0.8,1.0);
		program.use();
		cam.position.z = -1.0f;
		renderer.activeCamera = &cam;
		entity.position.z = 2.0f;


		
		
	}

	override void update()
	{
		
		//writeln(entity.transform.position);
		renderer.submitMesh!(EntityMaterial)(entity.mesh,entity.transform,entity.material);
		renderer.submitMesh!(EntityMaterial)(floor.mesh,floor.transform,floor.material);
		renderer.update();

	}

}

