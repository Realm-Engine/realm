module realmofthedead.gameentity;
import realm.engine.core;
import realm.engine.graphics.core;
import realm.engine.graphics.material;
import realm.engine.graphics.renderer;
import realm.engine.debugdraw;
import std.stdio;


 


mixin template GameEntity(string name ,T...)
{
	
	mixin RealmEntity!(name, T);
	private BlinnPhongMaterial material;
	public bool isStatic = true;
	private StandardShaderModel entityShader;
	StandardShaderModel getEntityShader()
	{
		if(entityShader is null)
		{
			entityShader = ShaderLibrary.getShader("$EngineAssets/Shaders/blinnphong.shader");
		}
		return entityShader;
	}

	ref BlinnPhongMaterial getMaterial()
	{
		return material;
	}

}
