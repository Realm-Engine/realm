module realmofthedead.game;
import realm.engine.app;
import realm.engine.core;
import realmofthedead.entitymanager;
import realm.engine.graphics.core;
import realm.engine.graphics.renderer;
import realm.engine.graphics.material;


class RealmGame : RealmApp
{

	private EntityManager _manager;
	Camera cam;
	private DirectionalLight mainLight;
	private Player player;
	private Gun gun;
	private IFImage gunDiffuse;
	this(int width, int height, const char* title,string[] args)
	{
		super(width,height,title,args);
		_manager = new EntityManager;
		VirtualFS.registerPath!("Projects/RealmOfTheDead/Assets")("Assets");
		cam = new Camera(CameraProjection.PERSPECTIVE,vec2(cast(float)width,cast(float)height) / 1,0.1,750,60);
		Renderer.get.activeCamera = &cam;
		SimpleMaterial.initialze();
		SimpleMaterial.reserve(2);


	}

	

	override void start()
	{
		gunDiffuse = readImageBytes("$Assets/Images/gun.png");
		mainLight.transform = new Transform;
		mainLight.color = vec3(1,1,1);
		mainLight.transform.rotation = vec3(0,90,0);
		//mainLight.transform.componentUpdate();
		Renderer.get.mainLight(&mainLight);
		Logger.LogInfo("Starting Realm of the Dead!");
		player = _manager.instantiate!(Player)(&cam);
		gun = _manager.instantiate!(Gun)(player.getComponent!(Transform));
		
		

	}

	override void update()
	{
	
		

		_manager.updateEntities();
		Renderer.get.update();

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

		mesh.calculateTangents();
		return mesh;

	}


}