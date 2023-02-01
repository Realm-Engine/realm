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

	
	material = new ToonMaterial();
	material.program = toonShader;
	material.baseColor = vec4(1.0f,0.0f,0.0f,1.0f);

	Entity sphere = ecs.createEntity();
	
	sphere.addComponent!(MeshRenderer)(loadMesh("$EngineAssets/Models/sphere.obj"),material.data);
	scene.add(sphere);
	sphere.getComponent!(Transform).scale = vec3(1);
	sphere.getComponent!(Transform).position = vec3(0,0,10);
	sphere.getComponent!(Transform).setRotationEuler(vec3(0f,90.0f,0f));
	
	ToonMaterial oilDrumMaterial = new ToonMaterial();
	oilDrumMaterial.baseColor = vec4(1.0f);
	sampler[SamplerParameter.MinFilter] = TextureFilterfunc.NEAREST;
	IFImage oilDrumImage = readImageBytes("$Assets/Images/oildrum_col.png");
	Texture2D oilDrumDiffuse = new Texture2D(&oilDrumImage);
	oilDrumMaterial.textures.diffuse = oilDrumDiffuse;

	Entity oildrum = ecs.createEntity();
	oildrum.addComponent!(MeshRenderer)(loadMesh("$Assets/Models/oildrum.obj"),material.data);
	scene.add(oildrum);


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

	Clip!(vec3,"position") animateMovement = new Clip!(vec3,"position");
	KeyFrame!(vec3) p1 = {vec3(0,0,10),0.0f};
	KeyFrame!(vec3) p2 = {vec3(0,0,0),10.0f};
	animateMovement.keyFrames=  [p1,p2];
	sphere.transform.animate!(vec3,"position")(animateMovement);

	
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


