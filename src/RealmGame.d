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
class RealmGame : RealmApp
{


	
	Entity entity;
	Entity floor;
	Queue!int queue;
	ShaderProgram program;
	Mesh triangle;
	Camera cam;
	Renderer renderer;
	Material!(["test":UserDataVarTypes.VECTOR]) material;

	this(int width, int height, const char* title)
	{
		
		

		super(width,height,title);
		material = new Material!(["test":UserDataVarTypes.VECTOR]);
		
		writeln(material.layout.test);
		renderer = new Renderer;
		cam = new Camera(CameraProjection.PERSPECTIVE,vec2(cast(float)width,cast(float)height),100,-0.1,45);
		auto vertexShader = read("./src/engine/res/vertexShader.glsl");
		auto fragmentShader = read("./src/engine/res/fragShader.glsl");
		Shader vertex = new Shader(ShaderType.VERTEX,cast(string) vertexShader,"Vetex Shader");
		Shader fragment = new Shader(ShaderType.FRAGMENT,cast(string)fragmentShader,"Fragment Shader");
		program = new ShaderProgram(vertex,fragment,"MyProgram");
		
		Mesh mesh = new Mesh;
		triangle = new Mesh;
		vec3[] square = [vec3(-0.5f,-0.5f,0),vec3(0.5,-0.5f,0),vec3(0.5,0.5f,0),vec3(-0.5,0.5f,0.0f)];
		triangle.positions = [vec3(-1,-1,0),vec3(-0.5,-0.5,0),vec3(0,-1,0)];
		triangle.faces = [0,1,2];
		mesh.textureCoordinates = [vec2(0,0),vec2(0,0),vec2(0,0),vec2(0,0)];
		mesh.calculateNormals();
		uint[] faces = [0,1,2,2,3,0];
		mesh.positions = square;
		mesh.faces = faces;
		mesh.calculateNormals();
		
		Transform transform = new Transform;	
		
		entity = new Entity(mesh,transform);
		floor = new Entity(mesh);
		floor.eulerRotation(vec3(90,0,0));
		floor.position = vec3(0,-0.2f,0);
		program.use();
		cam.position.z = -1.0f;
		renderer.activeCamera = &cam;
		entity.position.z = 2.0f;

		
	}

	override void update()
	{
		
		//writeln(entity.transform.position);
		renderer.submitMesh(entity.mesh,entity.transform);
		renderer.submitMesh(floor.mesh,floor.transform);
		renderer.update();

	}

}

