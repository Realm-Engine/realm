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
import realm.engine.staticgeometry;
import realm.engine.dynamicobjectlayer;
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
	private GameGeometry sphere;
	private StaticGeometryLayer geoLayer;
	float gamma = 1.0f;
	private Skybox skybox;
	private DynamicObjectLayer dynamicObjectLayer;
	this(int width, int height, const char* title,string[] args)
	{
		super(width,height,title,args);
		_manager = new EntityManager;
		VirtualFS.registerPath!("Projects/RealmOfTheDead/Assets")("Assets");
		cam = new Camera(CameraProjection.PERSPECTIVE,vec2(cast(float)width,cast(float)height) / 1,0.1,750,60);
		Renderer.get.activeCamera = &cam;
		BlinnPhongMaterial.initialze();
		BlinnPhongMaterial.reserve(4);
		//BlinnPhongMaterial.reserve(5);
		
		geoLayer = new StaticGeometryLayer;
		dynamicObjectLayer =new DynamicObjectLayer;

	}

	private void constructStaticGeometry()
	{
		geoLayer.initialize();
		GeometryList geoList;
		foreach(geo; _manager.getEntities!(GameGeometry))
		{
			
				geoList.meshes ~= (geo.getComponent!(Mesh)());
				geoList.transforms ~= geo.getComponent!(Transform)();
				BlinnPhongMaterial blinnPhongMat = geo.getMaterial();
				geoList.materials ~= blinnPhongMat;
			

		}

		geoLayer.submitGeometryList(geoList);


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

	void initSkybox()
	{
		skybox = new Skybox;
		IFImage[6] faces;
		faces[CubemapFaceIndex!(CubemapFace.POSITIVE_Y)] = readImageBytes("$Assets/Images/skybox/top.jpg");
		faces[CubemapFaceIndex!(CubemapFace.NEGATIVE_Y)] = readImageBytes("$Assets/Images/skybox/bottom.jpg");
		faces[CubemapFaceIndex!(CubemapFace.POSITIVE_X)] = readImageBytes("$Assets/Images/skybox/right.jpg");
		faces[CubemapFaceIndex!(CubemapFace.NEGATIVE_X)] = readImageBytes("$Assets/Images/skybox/left.jpg");
		faces[CubemapFaceIndex!(CubemapFace.POSITIVE_Z)] = readImageBytes("$Assets/Images/skybox/front.jpg");
		faces[CubemapFaceIndex!(CubemapFace.NEGATIVE_Z)] = readImageBytes("$Assets/Images/skybox/back.jpg");
		static foreach(face; CubemapFaces)
		{
			skybox.setFace!(face)(faces[CubemapFaceIndex!(face)]);
		}

		
	
	}

	override void start()
	{
		import std.uuid;
		
		
		
		initUI();
		
		
		dynamicObjectLayer.initialize();
		mainLight = _manager.instantiate!(DirectionalLight)();
		mainLight.color = vec3(1,1,1);
		mainLight.getComponent!(Transform).setRotationEuler(vec3(45,0,0));

		//mainLight.transform.componentUpdate();
		Renderer.get.mainLight(mainLight);
		Logger.LogInfo("Starting Realm of the Dead!");
		player = _manager.instantiate!(Player)(&cam,dynamicObjectLayer);
		gun = _manager.instantiate!(Gun)(player.getComponent!(Transform),cam,dynamicObjectLayer);
		sphere = _manager.instantiate!(GameGeometry)(loadMesh("$EngineAssets/Models/sphere.obj"));
		sphere.getComponent!(Transform).scale = vec3(0.5f);
		geo = _manager.instantiate!(GameGeometry)(loadMesh("$Assets/Models/crates.obj"));
		geo.entityName = "Crates";
		floor = _manager.instantiate!(GameGeometry)(generateFace(vec3(0,1,0),20));
		//GameGeometry floor2 = _manager.instantiate!(GameGeometry)(generateFace(vec3(0,0,-1),20));
		floor.entityName = "Floor";
		floor.active = true;
		//floor2.active = true;

		BlinnPhongMaterial sphereMaterial = sphere.getMaterial();
		sphereMaterial.ambient = vec4(0.01f);
		IFImage sphereNormal = readImageBytes("$EngineAssets/Images/Sphere-NormalMap.png");
		sphere.getComponent!(Transform)().scale = vec3(1,1,1);
		sphere.getComponent!(Transform)().position = vec3(0,5,0);
		sphere.active = false;
		sphereMaterial.textures.normal = new Texture2D(&sphereNormal);
		sphereMaterial.textures.diffuse = Vector!(int,4)(200,162,213,255);
		sphereMaterial.textures.specular = Vector!(int,4)(255);
		sphereMaterial.packTextureAtlas();
		
		BlinnPhongMaterial geoMaterial = geo.getMaterial();
		geo.setBaseMap(readImageBytes("$Assets/Images/crates.png"));
		geoMaterial.shininess = 16.0f;
		geoMaterial.textures.specular = Vector!(int,4)(255);
		geoMaterial.ambient = vec4(0.01);
		geoMaterial.textures.normal = Vector!(int,4)(0,0,255,255);

		geo.getComponent!(Transform).position = vec3(0,0,5);
		
		floor.setBaseMap(Vector!(int,4)(255));
		//floor2.setBaseMap(Vector!(int,4)(255,123,215,255));
		floor.getComponent!(Transform)().scale = vec3(10,1,10);
		floor.getComponent!(Transform)().position = vec3(0,-2,0);
		//floor2.getComponent!(Transform)().scale = vec3(10,1,10);
		//floor2.getComponent!(Transform)().position = vec3(5,-4,0);


		constructStaticGeometry();
		initSkybox();
		Renderer.get.setSkybox(skybox);
		skybox.freeFaces();
		
		
		

		


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
		Renderer.get.update(geoLayer,dynamicObjectLayer);

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