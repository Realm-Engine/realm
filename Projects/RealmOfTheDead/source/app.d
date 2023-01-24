module realmofthedead.app;

import std.stdio;
import realm.engine;
import std.file;
import realm.engine.layer3d;
import realm.engine.graphics.graphicssubsystem;
mixin RealmMain!(&init,&start,&update);


StandardShaderModel toonShader;
ToonMaterial material;
Mesh triangle;

Layer3D layer;

RealmInitDesc init(string[] args)
{
	RealmInitDesc desc;
	desc.width = 1280;
	desc.height = 720;
	desc.title = "Realm of the Dead!";
	return desc;

}

bool update(float dt)
{
	toonShader.use();
	layer.drawTo!(ToonMaterial)(triangle,material);
	

	return false;
}

void start()
{
	
	VirtualFS.registerPath!("Projects/RealmOfTheDead/Assets")("Assets");
	Logger.LogInfo("Hello realm!");
	string vtxPath = "$EngineAssets/Shaders/toon-vertex.glsl";
	string fragPath = "$EngineAssets/Shaders/toon-fragment.glsl";
	toonShader = new StandardShaderModel("Toon");
	layer = new Layer3D();
	Shader vertexShader = new Shader(ShaderType.VERTEX,readText(VirtualFS.getSystemPath(vtxPath)),VirtualFS.getFileName(vtxPath));
	Shader fragmentShader = new Shader(ShaderType.FRAGMENT,readText(VirtualFS.getSystemPath(fragPath)),VirtualFS.getFileName(fragPath));
	triangle.positions = [vec3(0,0.5,0),vec3(-0.5,-0.5,0),vec3(0.5,-0.5,0)];
	triangle.faces = [0,1,2];
	
	toonShader.vertexShader = vertexShader;
	toonShader.fragmentShader = fragmentShader;
	toonShader.compile();

	GraphicsSubsystem.setClearColor(0,0,0,false);
	material = new ToonMaterial();
	material.program = toonShader;
	material.baseColor = vec4(1.0f,0.0f,0.0f,1.0f);

	
}


