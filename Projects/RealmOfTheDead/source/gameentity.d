module realmofthedead.gameentity;
import realm.engine.core;
import realm.engine.graphics.core;
import realm.engine.graphics.material;
import realm.engine.graphics.renderer;
import realm.engine.debugdraw;
import std.stdio;
alias SimpleMaterial = Alias!(Material!(["color" : UserDataVarTypes.VECTOR,
										 "diffuse" : UserDataVarTypes.TEXTURE2D,
										 "normal" : UserDataVarTypes.TEXTURE2D,
										 "specularPower" : UserDataVarTypes.FLOAT,
										 "shinyness" : UserDataVarTypes.FLOAT],2));
static StandardShaderModel entityShader;

 


mixin template GameEntity(string name ,T...)
{
	
	mixin RealmEntity!(name, T);
	private SimpleMaterial material;

	static StandardShaderModel getEntityShader()
	{
		if(entityShader is null)
		{
			entityShader = loadShaderProgram("$EngineAssets/Shaders/simpleShaded.shader","Simple shader");
		}
		return entityShader;
	}

	SimpleMaterial getMaterial()
	{
		return material;
	}

}
