module realm.gameentity;
import realm.engine.core;
import realm.engine.graphics.core;
import realm.engine.graphics.material;
import realm.engine.graphics.renderer;

alias SimpleMaterial = Alias!(Material!(["color" : UserDataVarTypes.VECTOR]));

class GameEntity
{
	
	mixin RealmEntity!(Transform,Mesh);
	private SimpleMaterial material;
	private ShaderProgram shader;
	private static IFImage diffuse;
	this(string modelPath)
	{
		transform = new Transform;
		mesh = loadMesh(modelPath);
		SimpleMaterial.initialze();
		SimpleMaterial.reserve(1);
		material = new SimpleMaterial;
		shader = loadShaderProgram("./src/engine/Assets/Shaders/simpleShaded.shader","Simple shaded");
		material.setShaderProgram(shader);
		material.color = vec4(0.5);
		
		material.packTextureAtlas();

		
	}

	void update()
	{
		updateComponents();


	}


	void draw(Renderer renderer)
	{
		renderer.submitMesh!(SimpleMaterial)(mesh,transform,material);
	}


}