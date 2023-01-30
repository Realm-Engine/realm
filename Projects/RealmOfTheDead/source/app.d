module realmofthedead.app;

import std.stdio;
import realm.engine;
import std.file;
import realm.engine.layer3d;
import realm.engine.ecs;
import realm.engine.scene;
import realmofthedead.playercontroller;
import realm.engine.animation.clip;
mixin ECS!(Transform,MeshRenderer,Camera,PlayerController);
mixin RealmMain!(&init,&start,&update);



StandardShaderModel toonShader;
ToonMaterial material;


Layer3D layer;
ECS ecs;
Scene!(ECS) scene;
Entity player;
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

	Entity entity = ecs.createEntity();
	
	entity.addComponent!(MeshRenderer)(loadMesh("$EngineAssets/Models/sphere.obj"),material.data);
	scene.add(entity);
	entity.getComponent!(Transform).scale = vec3(1);
	entity.getComponent!(Transform).position = vec3(0,0,10);
	entity.getComponent!(Transform).setRotationEuler(vec3(0f,90.0f,0f));


	Entity mainCamera = ecs.createEntity();
	
	mainCamera.addComponent!(Camera)(CameraProjection.PERSPECTIVE,vec2(cast(float)windowWidth,cast(float)windowHeight),0.1,750,60);
	//scene.add(mainCamera);
	//player = ecs.createEntity();
	mainCamera.addComponent!(PlayerController)();
	
	Clip!(vec3,"position") clip = new Clip!(vec3,"position");
	KeyFrame!(vec3) frame1,frame2,frame3,frame4;
	frame1.value = vec3(0.0f,0.0f,10.0f);
	frame1.time = 0.0f;
	frame2.value = vec3(5.0f,0.0f,10.0f);
	frame2.time = 2.0f;
	frame3.value = vec3(5.0f,0.0f,5.0f);
	frame3.time = 4.0f;
	frame4.value = vec3(0.0f,0.0f,5.0f);
	frame4.time = 6.0f;
	clip.addKeyFrame(frame1);
	clip.addKeyFrame(frame2);
	clip.addKeyFrame(frame3);
	clip.addKeyFrame(frame4);
	entity.transform.animate!(vec3,"position")(clip);
	
	//mainCamera.transform.setParent(player.transform);
	scene.add(mainCamera);
	
	

	
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
	desc.clearColor = [1,1,1,1];
	desc.updateContext = &updateGraphicsContext;


	return desc;

}

private pipeline.GraphicsContext updateGraphicsContext(pipeline.GraphicsContext currentCtx)
{
	Camera* camera = scene.findComponent!(Camera);
	if(camera !is null)
	{
		//Logger.LogInfo("%s",camera.eid.toString());
		currentCtx.viewMatrix = camera.view.transposed.value_ptr[0..16];
		currentCtx.projectionMatrix = camera.projection.transposed.value_ptr[0..16];
	}
	return currentCtx;
}


