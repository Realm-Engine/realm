module realmofthedead.game;
import realm.engine.app;
import realm.engine.core;
import realmofthedead.entitymanager;
import realm.engine.graphics.core;
import realm.engine.graphics.renderer;
import realm.engine.graphics.material;
import realm.engine.ui.realmui;
import realm.engine.physics.core :physicsWorld,PhysicsBody;
import realm.engine.graphics.renderpass;
import realm.engine.memory;
import core.lifetime;
import std.exception;
import std.conv;
class RealmGame : RealmApp
{

	private EntityManager _manager;
	Camera cam;
	private DirectionalLight mainLight;
	private Player player;
	private Gun gun;
	private GameGeometry geo;
	private GameGeometry floor;
	private RealmUI.UIElement renderTime;
	private RealmUI.UIElement debugPanel;
	private RealmUI.UIElement deltaTime;
	private RealmUI.UIElement graphicsPanel;
	private RealmUI.UIElement gammaSlider;
	float gamma = 1.0f;
	this(int width, int height, const char* title,string[] args)
	{
		super(width,height,title,args);
		_manager = new EntityManager;
		VirtualFS.registerPath!("Projects/RealmOfTheDead/Assets")("Assets");
		cam = new Camera(CameraProjection.PERSPECTIVE,vec2(cast(float)width,cast(float)height) / 1,0.1,750,60);
		Renderer.get.activeCamera = &cam;
		SimpleMaterial.initialze();
		SimpleMaterial.reserve(4);

	}

	void initUI()
	{

		auto windowSize = RealmApp.getWindowSize();
		RealmUI.themePush(RealmUI.UITheme(vec4(1),vec4(0,0,0,1)));
		debugPanel =RealmUI.createElement(vec3(windowSize[0]-200,windowSize[1] - 200, 0),vec3(300,200,1),vec3(0));
		deltaTime = RealmUI.createElement(vec3(0,100,0),vec3(300,25,1),vec3(0));
		renderTime = RealmUI.createElement(vec3(0,0,0),vec3(300,25,1),vec3(0));
		renderTime.textLayout = RealmUI.TextLayout(4,6,12);
		deltaTime.textLayout =  RealmUI.TextLayout(4,6,12);
		graphicsPanel = RealmUI.createElement(vec3(windowSize[0]-800,windowSize[1]-200,0),vec3(300,200,1),vec3(0));
		gammaSlider = RealmUI.createElement(vec3(windowSize[0]-800,windowSize[1]-200,0),vec3(300,25,1),vec3(0));
		
		
	}

	override void start()
	{
		import std.uuid;
		
		
		
		initUI();
		
		
		
		mainLight = _manager.instantiate!(DirectionalLight)();
		mainLight.color = vec3(1,1,1);
		mainLight.getComponent!(Transform).setRotationEuler(vec3(45,0,0));

		//mainLight.transform.componentUpdate();
		Renderer.get.mainLight(mainLight);
		Logger.LogInfo("Starting Realm of the Dead!");
		player = _manager.instantiate!(Player)(&cam);
		gun = _manager.instantiate!(Gun)(player.getComponent!(Transform),cam);
		geo = _manager.instantiate!(GameGeometry)(loadMesh("$Assets/Models/crates.obj"));
		geo.entityName = "Crates";
		floor = _manager.instantiate!(GameGeometry)(generateFace(vec3(0,1,0),8));
		floor.entityName = "Floor";
		SimpleMaterial geoMaterial = geo.getMaterial();
		geo.setBaseMap(readImageBytes("$Assets/Images/crates.png"));
		geoMaterial.shinyness = 32.0f;
		geoMaterial.specularPower = 1.0f;
		geoMaterial.color = vec4(1);
		
		geo.getComponent!(Transform).position = vec3(0,0,5);
		
		floor.setBaseMap(Vector!(int,4)(255));
		floor.getComponent!(Transform)().scale = vec3(10,1,10);
		floor.getComponent!(Transform)().position = vec3(0,-2,0);

		

		


	}

	void drawUI()
	{
		import std.format;
		double drawTime = Renderer.get.getMetrics().frameTime;
		RealmUI.drawPanel(debugPanel);
		RealmUI.containerPush(debugPanel);
		float dt = getAppMetrics().deltaTime;
		RealmUI.drawTextString(deltaTime,"Delta Time: %f",dt);
		RealmUI.drawTextString(renderTime,"Frame draw time: %f", drawTime);
		RealmUI.containerPop();
		
		//RealmUI.containerPush(graphicsPanel);
		
		gamma = RealmUI.slider(gammaSlider,gamma);
		Renderer.get.getScreenPassMaterial().gamma = 2.2f * gamma;
		

		
		//RealmUI.containerPop();
		
	}
	override void update()
	{
	
		//floor.getComponent!(Transform).rotateEuler(vec3(0,0,0));
		float dt = getAppMetrics().deltaTime;
		_manager.updateEntities(dt / 100);
		physicsWorld.tick(dt / 100);
		drawUI();
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