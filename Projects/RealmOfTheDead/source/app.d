module realmofthedead.app;

import std.stdio;
import realm.engine;
import std.file;
import realm.engine.layer3d;
import realm.engine.ecs;
import realm.engine.scene;
import realmofthedead.playercontroller;
import realm.engine.animation.clip;
mixin ECS!(Transform,MeshRenderer,Camera,PlayerController,DirectionalLight);
mixin RealmMain!(&init,&start,&update);



StandardShaderModel toonShader;
ToonMaterial material;


Layer3D layer;
ECS ecs;
Scene!(ECS) scene;
Entity player;
Sampler sampler;
RealmInitDesc init(string[] args)
{
	
	RealmInitDesc desc;
	desc.width = 1280;
	desc.height = 720;
	desc.title = "Realm of the Dead!";
	desc.initPipelineFunc = &renderPipelineInit;
	VirtualFS.registerPath!("Projects/RealmOfTheDead/Assets")("Assets");
	ecs = new ECS();
	scene = new Scene!(ECS)(ecs);
	return desc;

}





bool update(float dt)
{
	ecs.update();	
	scene.draw(layer);
	
	
	return false;
}

void start()
{
	
	layer = new Layer3D();
	
	Logger.LogInfo("Hello realm!");
	string vtxPath = "$EngineAssets/Shaders/toon-vertex.glsl";
	string fragPath = "$EngineAssets/Shaders/toon-fragment.glsl";
	toonShader = new StandardShaderModel("Toon");
	
	Shader vertexShader = new Shader(ShaderType.VERTEX,readText(VirtualFS.getSystemPath(vtxPath)),VirtualFS.getFileName(vtxPath));
	Shader fragmentShader = new Shader(ShaderType.FRAGMENT,readText(VirtualFS.getSystemPath(fragPath)),VirtualFS.getFileName(fragPath));
	
	
	toonShader.vertexShader = vertexShader;
	toonShader.fragmentShader = fragmentShader;
	toonShader.compile();
	sampler.create();
	sampler[SamplerParameter.MinFilter] = TextureFilterfunc.NEAREST;
	sampler[SamplerParameter.MagFilter] = TextureFilterfunc.NEAREST;
	sampler[SamplerParameter.WrapS] = TextureWrapFunc.CLAMP_TO_EDGE;
	sampler[SamplerParameter.WrapT] = TextureWrapFunc.CLAMP_TO_EDGE;
	
	ToonMaterial oilDrumMaterial = new ToonMaterial();
	oilDrumMaterial.baseColor = vec4(1.0f);
	IFImage oilDrumImage = readImageBytes("$Assets/Images/OilDrum/oildrum_col.png");

	Texture2D oilDrumDiffuse = new Texture2D(&oilDrumImage);
	oilDrumMaterial.textures.diffuse = oilDrumDiffuse;
	oilDrumMaterial.textures.diffuse_Sampler = sampler;
	oilDrumMaterial.program = toonShader;
	Entity oildrum = ecs.createEntity();
	oildrum.addComponent!(MeshRenderer)(loadMesh("$Assets/Models/oildrum.obj"),oilDrumMaterial.data);
	scene.add(oildrum);
	
	IFImage floorDiffuseImage = readImageBytes("$Assets/Images/FloorTile/FloorTileDiffuse.png");
	Texture2D floorDiffuseTexture = new Texture2D(&floorDiffuseImage);
	Entity floor = ecs.createEntity();
	ToonMaterial floorMaterial = new ToonMaterial();
	floorMaterial.program = toonShader;
	floorMaterial.baseColor = vec4(1.0f);
	floorMaterial.textures.diffuse = floorDiffuseTexture;
	floorMaterial.textures.diffuse_Sampler = sampler;
	floor.addComponent!(MeshRenderer)(util.generateFace(vec3(0,1,0),5),floorMaterial.data);
	floor.transform.scale = vec3(5.0f);
	floor.transform.position = vec3(0,-1.0f,0);
	scene.add(floor);

	Entity mainCamera = ecs.createEntity();
	mainCamera.addComponent!(Camera)(CameraProjection.PERSPECTIVE,vec2(cast(float)windowWidth,cast(float)windowHeight),0.1,750,60);
	mainCamera.addComponent!(PlayerController)();
	
	//mainCamera.transform.setParent(player.transform);
	scene.add(mainCamera);
	
	Entity sun = ecs.createEntity();
	DirectionalLight mainLight = sun.addComponent!(DirectionalLight)();
	scene.add(sun);

	Clip!(quat,"rotation") sunRotation = new Clip!(quat,"rotation");
	KeyFrame!(quat) f1 = {quat.euler_rotation(45,0,0),0.0f};
	KeyFrame!(quat) f2 = {quat.euler_rotation(45,90,0),5.0f};
	KeyFrame!(quat) f3 = {quat.euler_rotation(45,180,0),10.0f};
	sunRotation.keyFrames = [f1,f2,f3];
	mainLight.transform.animate!(quat,"rotation")(sunRotation);



	
}



private pipeline.PipelineInitDesc renderPipelineInit()
{
	import gl3n.linalg;
	pipeline.GraphicsContext ctx;
	ctx.viewMatrix = mat4.identity.value_ptr[0..16];
	ctx.projectionMatrix = mat4.identity.value_ptr[0..16];
	ctx.lightInfo.direction = vec4(0f,-0.5f,1.0f,1.0f).value_ptr[0..4];
	pipeline.PipelineInitDesc desc;
	desc.initialContext = ctx;
	desc.clearColor = [0xB9/255.0f,0xF3/255.0f,0xFC/255.0f,1];
	desc.updateContext = &updateGraphicsContext;


	return desc;

}

private pipeline.GraphicsContext updateGraphicsContext(pipeline.GraphicsContext currentCtx)
{
	Camera* camera = scene.findComponent!(Camera);
	if(camera !is null)
	{
		
		currentCtx.viewMatrix = camera.view.transposed.value_ptr[0..16];
		currentCtx.projectionMatrix = camera.projection.transposed.value_ptr[0..16];
	}
	DirectionalLight* mainLight = scene.findComponent!(DirectionalLight);
	if(mainLight !is null)
	{
		currentCtx.lightInfo.direction = mainLight.transform.front.value_ptr[0..4];
	}
	return currentCtx;
}


