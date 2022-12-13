module realmofthedead.gamegeometry;
import realmofthedead.gameentity;
private
{
	import realm.engine.core;
	import realm.engine.graphics.core;
	import realm.engine.graphics.material;
	import realm.engine.graphics.renderer;
	import realm.engine.debugdraw;
	import realm.engine.physics.core;

}

class GameGeometry
{
	mixin GameEntity!("Geometry",Transform,Mesh,MeshCollider,PhysicsBody);
	private Mesh* mesh;
	private Transform transform;
	private Texture2D diffuseMap;
	void start(Mesh geo)
	{
		mesh = &getComponent!(Mesh)();
		transform = getComponent!(Transform)();
		*mesh = geo;
		material = new BlinnPhongMaterial;
		
		material.textures.normal = Vector!(int,4)(0,0,255,0);
		material.setShaderProgram(getEntityShader());
		material.shininess = 16;
		material.textures.specular = Vector!(int,4)(255);
		material.ambient = vec4(0.1);
		

	}
	
	void setBaseMap(Vector!(int,4) color)
	{
		material.textures.diffuse = color;
		material.textures.settings = TextureDesc(ImageFormat.RGBA8,TextureFilterfunc.NEAREST,TextureWrapFunc.CLAMP_TO_BORDER);
		material.packTextureAtlas();
	}

	void setBaseMap(IFImage image)
	{
		material.textures.diffuse = new Texture2D(&image);
		material.textures.settings = TextureDesc(ImageFormat.SRGBA8,TextureFilterfunc.NEAREST,TextureWrapFunc.CLAMP_TO_EDGE);
		material.packTextureAtlas();
		
	}

	void update(float dt)
	{
		updateComponents();
		//if(isStatic)
		//{
		//    Renderer.get.submitMesh!(SimpleMaterial,true)(mesh,transform,material,vertexBuffer);
		//}
		//else
		//{
		//    Renderer.get.submitMesh!(SimpleMaterial,false)(mesh,transform,material,vertexBuffer);
		//}
		
	}


}