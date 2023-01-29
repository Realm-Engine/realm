module realmofthedead.playercontroller;
import realmofthedead.app;
import realm.engine.ecs;
import realm.engine;
class PlayerController
{
	mixin RealmComponent;

	float lastX;
    float lastY;
    float lastScrollX;
    float lastScrollY;
    vec2 rotation;
    
    
	void componentStart()
	{
        rotation = vec2(0,0);
	}

	void componentUpdate()
	{
		//Logger.LogInfo("%s",eid.toString());
        processInput();
        
	}

	vec2 transformMouse(vec2 mouse)
    {
       
        return vec2(mouse.x * 2.0f / windowWidth- 1.0f, 1.0f - 2.0f * mouse.y / windowHeight);
    }

	void processInput()
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
	}

	


}


