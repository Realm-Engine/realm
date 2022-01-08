module realm.gameentity;
import realm.engine.core;
import realm.engine.graphics.core;
import realm.engine.graphics.material;
import realm.engine.graphics.renderer;
import realm.engine.debugdraw;
import std.stdio;
alias SimpleMaterial = Alias!(Material!(["color" : UserDataVarTypes.VECTOR,
										 "specularPower" : UserDataVarTypes.FLOAT,
										 "shinyness" : UserDataVarTypes.FLOAT],2));

class GameEntity
{
	
	mixin RealmEntity!(Transform,Mesh);
	private SimpleMaterial material;
	private static ShaderProgram shader;
	private static IFImage diffuse;
	
	this(string modelPath)
	{
		transform = new Transform;
		
		if(shader is null)
		{
			shader = loadShaderProgram("./src/engine/Assets/Shaders/simpleShaded.shader","Simple shaded");
		}
		mesh = loadMesh(modelPath);
		SimpleMaterial.allocate(&mesh);
		material = new SimpleMaterial;
		material.specularPower = 1.0;
		material.shinyness = 32;
		material.setShaderProgram(shader);
		material.color = vec4(1.0,1.0,1.0,1.0);
	}
	static this()
	{
		
	}
	@property color(vec4 color)
	{
		material.color = color;
	}

	void update()
	{
		updateComponents();
		

	}

	SimpleMaterial* getMaterial()
	{
		return &material;
	}


	void draw(Renderer renderer)
	{
		renderer.submitMesh!(SimpleMaterial)(mesh,transform,material);

	}
	void debugDraw()
	{
		
		//Debug.drawBox(getComponent!(BoundingBox).center(),getComponent!(BoundingBox).extents(),vec3(0));
	}


}