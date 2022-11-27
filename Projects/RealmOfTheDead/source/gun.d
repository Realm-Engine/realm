module realmofthedead.gun;
import realm.engine.core;
import realmofthedead.gameentity;
private
{
	import realm.engine.core;
	import realm.engine.graphics.core;
	import realm.engine.graphics.material;
	import realm.engine.graphics.renderer;
	import realm.engine.debugdraw;
	import realm.engine.physics.core;
	import realmofthedead.gamegeometry;

}
class Gun
{
	mixin GameEntity!("Gun",Transform,Mesh);
	private IFImage diffuseImage;
	private Mesh* mesh;
	private Transform transform;
	private RealmVertex[] vertexBuffer;
	void start(Transform player, Camera camera)
	{
		
		diffuseImage = readImageBytes("$Assets/Images/gun.png");
		mesh = &getComponent!(Mesh)();
		transform = getComponent!(Transform)();
		*mesh = loadMesh("$Assets/Models/gun.obj");
		transform.setParent(player);
		material = new BlinnPhongMaterial;
		BlinnPhongMaterial.allocate(mesh);
		material.shininess = 1.0f;
		material.textures.specular = Vector!(int,4)(255);
		material.textures.normal = Vector!(int, 4)(0);
		material.ambient = vec4(1);
		material.textures.diffuse = new Texture2D(&diffuseImage);
		material.textures.settings = TextureDesc(ImageFormat.SRGBA8,TextureFilterfunc.NEAREST,TextureWrapFunc.CLAMP_TO_BORDER);
		material.packTextureAtlas();
		material.setShaderProgram(getEntityShader());
		transform.position = vec3(-1.5,1,3);
		transform.scale = vec3(1,1,1);
		//transform.rotation = vec3(0,0,0);
		transform.setRotationEuler(vec3(0,-80,0));
		vertexBuffer.length = mesh.positions.length;
		
		


		scope(exit)
		{
			diffuseImage.free();
		}
	}

	
	
	void processInput(float dt)
	{
		if(InputManager.getMouseButton(RealmMouseButton.ButtonLeft))
		{
			//Logger.LogInfo("Shoot");
			vec3 rayStart = transform.getWorldPosition + vec3(0,0,5);
			vec3 rayEnd = rayStart + ((transform.getWorldRotation *  vec3(1,0,0)) * 100);
			
			Debug.drawLine(rayStart,rayEnd);

			if(physicsWorld.raycast(rayStart,rayEnd))
			{
				Logger.LogInfo("gun hit!");
			}

		}
	}

	void update(float dt)
	{
		vec3 front = transform.front();
		vec3 position = transform.position;
		//processInput(dt);
		//Logger.LogInfo("%f %f %f", position.x, position.y,position.z);
		//processCollisions();
		//transform.rotateEuler(vec3(0,0,0));
		updateComponents();
		Renderer.get.submitMesh!(BlinnPhongMaterial,false)(mesh,transform,material,vertexBuffer);
	}

}