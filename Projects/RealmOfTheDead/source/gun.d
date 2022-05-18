module realmofthedead.gun;
import realm.engine.core;
import realmofthedead.gameentity;
private
{
	import realm.engine.physics.collision;
	import realm.engine.core;
	import realm.engine.graphics.core;
	import realm.engine.graphics.material;
	import realm.engine.graphics.renderer;
	import realm.engine.debugdraw;
	import realm.engine.physics.collision;

}
class Gun
{
	mixin GameEntity!("Gun",Transform,Mesh, SimpleCollider);
	private IFImage diffuseImage;
	private Mesh* mesh;
	private Transform transform;

	void start(Transform player)
	{
		diffuseImage = readImageBytes("$Assets/Images/gun.png");
		mesh = &getComponent!(Mesh)();
		transform = getComponent!(Transform)();
		*mesh = loadMesh("$Assets/Models/gun.obj");
		//transform.setParent(player);
		material = new SimpleMaterial;
		SimpleMaterial.allocate(mesh);
		material.shinyness = 1.0f;
		material.specularPower = 1.0f;
		material.textures.normal = Vector!(int, 4)(0);
		material.color = vec4(1);
		material.textures.diffuse = new Texture2D(&diffuseImage);
		material.textures.settings = TextureDesc(ImageFormat.RGBA8,TextureFilterfunc.NEAREST,TextureWrapFunc.CLAMP_TO_BORDER);
		material.packTextureAtlas();
		material.setShaderProgram(getEntityShader());

		transform.scale = vec3(0.5,0.5,0.5);
		transform.rotation = vec3(0,0,90);
		transform.position =vec3(0,0,0);


		scope(exit)
		{
			diffuseImage.free();
		}
	}

	 

	void update()
	{
		updateComponents();
		Renderer.get.submitMesh!(SimpleMaterial,false)(*mesh,transform,material);
	}

}