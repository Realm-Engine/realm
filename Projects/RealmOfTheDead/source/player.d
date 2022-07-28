module realmofthedead.player;
import realm.engine.core;
import std.stdio;
import realm.engine.app;
import std.typecons;

private
{
    import realmofthedead.gun;
    import realm.engine.physics.core;
    import realmofthedead.gamegeometry;
    import realmofthedead.gameentity;
	import realm.engine.graphics.core;
	import realm.engine.graphics.material;
	import realm.engine.graphics.renderer;
}



class Player
{
    private Camera* camera;

    mixin GameEntity!("Player",Transform,Mesh,MeshCollider,PhysicsBody);
    float lastX;
    float lastY;
    float lastScrollX;
    float lastScrollY;
    private Transform transform;
    vec2 rotation;
    private PhysicsBody physicsBody;
    private BoxCollider* collider;
    private Mesh* mesh;
    float gravity = 9.82;
    bool onGround;
    private RealmVertex[] vertexBuffer;
    void start(Camera* cam)
    {

        lastX = float.max;
        lastY = float.max;

        this.camera = cam;
        camera.position = vec3(0,2,2);
		//collider = &(getComponent!(BoxCollider)());
		////collider.center = vec3(0,1,0);
		//collider.center = vec3(1);
		//collider.setSize(2,5,2);
        mesh = &(getComponent!(Mesh)());
        *mesh = loadMesh("$Assets/Models/Player.obj");
        material = new SimpleMaterial;
		SimpleMaterial.allocate(mesh);
		material.shinyness = 1.0f;
		material.specularPower = 1.0f;
		material.textures.normal = Vector!(int, 4)(0);
		material.color = vec4(1);
		material.textures.diffuse = Vector!(int, 4)(255);
		material.textures.settings = TextureDesc(ImageFormat.RGBA8,TextureFilterfunc.NEAREST,TextureWrapFunc.CLAMP_TO_BORDER);
		material.packTextureAtlas();
		material.setShaderProgram(getEntityShader());

        //camera.transform.setRotationEuler(vec3(0,90,0));
        //camera.turn(vec2(90,-80));
        //camera.update();
		// setComponent!(Transform)(new Transform);
        transform = getComponent!(Transform);
        //transform.setParent(*camera);
        camera.setParent(transform);
		camera.setRotationEuler(vec3(45,0,0));
        InputManager.registerInputEventCallback(&inputEvent);
        rotation = vec2(0,0);
        physicsBody = getComponent!(PhysicsBody)();
        transform.position = vec3(0,5,-7);
        camera.transform.position = transform.position - vec3(0,-3,-5);
        vertexBuffer.length = mesh.positions.length;
        //physicsBody.active = false;
    }

    vec2 transformMouse(vec2 mouse)
    {
        Tuple!(int, int) windowSize = RealmApp.getWindowSize();
        return vec2(mouse.x * 2.0f / windowSize[0] - 1.0f, 1.0f - 2.0f * mouse.y / windowSize[1]);
    }

    void inputEvent(InputEvent event)
	{


	}

    void processInput(float dt)
    {
        float x = cast(float) InputManager.getMouseAxis(MouseAxis.X);

        float y = cast(float) InputManager.getMouseAxis(MouseAxis.Y);
        if (lastX == float.max)
        {
            lastX = x;

        }
        if (lastY == float.max)
        {
            lastY = y;
        }
        vec2 mouse = transformMouse(vec2(x, y));
        vec2 prevMouse = vec2(lastX, lastY);
        vec3 movementVector = vec3(0);
        if(InputManager.getKey(RealmKey.W) == KeyState.Press)
		{
            movementVector += transform.front;
		}
		else if(InputManager.getKey(RealmKey.S) == KeyState.Press)
		{
            movementVector -= transform.front;
		}
		if(InputManager.getKey(RealmKey.A) == KeyState.Press)
		{
            movementVector -= transform.front.cross(vec3(0,1,0)).normalized() ;
		}
		else if(InputManager.getKey(RealmKey.D) == KeyState.Press)
		{
            movementVector += transform.front.cross(vec3(0,1,0)).normalized() ;
		}
        //Logger.LogInfo("DT: %f", dt);
        if(!onGround)
		{
            movementVector.y -= 1 * dt;
		}

        
        transform.position += movementVector;
        float xOffset = x - lastX;
        float yOffset = lastY - y;
        xOffset *= 0.001;
        yOffset*= 0.001;
        
       
        if (InputManager.getMouseButton(RealmMouseButton.ButtonLeft) == KeyState.Press )
        {
            rotation.x += xOffset ;
            rotation.y += yOffset ;
            rotation.y = clamp(rotation.y,-88.0f,88.0f);
            auto xQuat = quat.axis_rotation(rotation.x,vec3(0,1,0));
            auto yQuat = quat.axis_rotation(rotation.y,vec3(-1,0,0));
            transform.rotation = xQuat * yQuat;
            //camera.transform.rotation = transform.rotation;
        }
        if (InputManager.getKey(RealmKey.Right) == KeyState.Press)
        {

            //camera.turn(vec2(1,0));
            //getComponent!(ArcballCamera)().rotate(prevMouse,mouse);
        }
        if(InputManager.getKey(RealmKey.Space) == KeyState.Press)
		{

			double zoom = InputManager.getMouseScroll(ScrollOffset.Y);
            if(zoom != lastScrollY)
			{

                lastScrollY = zoom;
			}

		}


        lastX = x;
        lastY =y;
        vec3 moveVector = vec3(0, 0, 0);


        //arcballcamera.pan(vec2(lastX,lastY),vec2(x,y));

    }

    void processCollisions()
	{
		import std.variant;
		PhysicsBody[] collisions = physicsBody.getCollisions();

		foreach(physicsBody; collisions)
		{
			Variant collidingObject = physicsBody.getParentObject();
			if(collidingObject.peek!(GameGeometry) !is null)
			{
				auto geo = collidingObject.peek!(GameGeometry)();
                if(geo.entityName == "Floor")
				{
                    onGround = true;
                    Logger.LogInfo("On ground");
				}
				
			}
		}

	}

    void update(float dt)
    {
       
        processInput(dt);
        camera.update();
        updateComponents();
        processCollisions();
        Renderer.get.submitMesh!(SimpleMaterial,false)(mesh,transform,material,vertexBuffer);

        
        
        
        //camera.view = getComponent!(ArcballCamera).camera;
    }



}