module realm.game;
import realm.engine.app;
import std.stdio;
import realm.engine.core;
import gl3n.linalg;
import realm.entity;
import realm.engine.containers.queue;
import realm.engine.graphics.core;
import realm.engine.graphics.graphicssubsystem;
import std.file : read;
class RealmGame : RealmApp
{
	Entity entity;
	Queue!int queue;
	ShaderProgram program;
	GraphicsSubsystem gss;
	this(int width, int height, const char* title)
	{
		

		super(width,height,title);
		gss = new GraphicsSubsystem();
		auto vertexShader = read("./src/engine/res/vertexShader.glsl");
		auto fragmentShader = read("./src/engine/res/fragShader.glsl");
		Shader vertex = new Shader(ShaderType.VERTEX,cast(string) vertexShader,"Vetex Shader");
		Shader fragment = new Shader(ShaderType.FRAGMENT,cast(string)fragmentShader,"Fragment Shader");
		program = new ShaderProgram(vertex,fragment,"MyProgram");
		
		Mesh mesh = new Mesh;
		
		vec3[] square = [vec3(-0.5f,-0.5f,0),vec3(0.5,-0.5f,0),vec3(0.5,0.5f,0),vec3(-0.5,0.5f,0.0f)];
		uint[] faces = [0,1,2,2,3,0];
		mesh.positions = square;
		mesh.faces = faces;
		mesh.calculateNormals();
		
		Transform transform = new Transform;	
		
		entity = new Entity(mesh,transform);
		program.use();


		
	}

	override void update()
	{
		Mesh[] meshes;
		meshes~= entity.mesh;
		gss.drawMultiMeshIndirect(meshes);

	}

}

