module realm.gameentity;
import realm.engine.core;
import realm.engine.graphics.core;
import realm.engine.graphics.material;
import realm.engine.graphics.renderer;

alias SimpleMaterial = Alias!(Material!(["color" : UserDataVarTypes.VECTOR,
										 "specularPower" : UserDataVarTypes.FLOAT]));

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

		material = new SimpleMaterial;
		shader = loadShaderProgram("./src/engine/Assets/Shaders/simpleShaded.shader","Simple shaded");
		material.setShaderProgram(shader);
		material.color = vec4(1.0);
		material.specularPower = 1.0f;
		material.packTextureAtlas();

		
	}
	@property color(vec4 color)
	{
		material.color = color;
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