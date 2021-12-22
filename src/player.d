module realm.player;
import realm.engine.core;
import realm.engine.ecs;
import realm.engine.input;
import realm.engine.logging;
import realm.arcballcamera;
import std.stdio;
import realm.engine.app;
import std.typecons;

class Player
{
    private Camera* camera;

    mixin RealmEntity!(Transform, ArcballCamera);
    float lastX;
    float lastY;
    this(Camera* cam)
    {
        lastX = float.max;
        lastY = float.max;

        this.camera = cam;
        camera.position = vec3(0, 0, 0);
        transform = new Transform();
        arcballcamera = new ArcballCamera(cam.position, cam.position + vec3(0,
                0, 1), vec3(0, 1, 0));

    }

    vec2 transformMouse(vec2 mouse)
    {
        Tuple!(int, int) windowSize = RealmApp.getWindowSize();
        return vec2(mouse.x * 2.0f / windowSize[0] - 1.0f, 1.0f - 2.0f * mouse.y / windowSize[1]);
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

        if (InputManager.getKey(RealmKey.Left) == KeyState.Press )
        {

           camera.turn(vec2(-1,0));
            //getComponent!(ArcballCamera)().rotate(prevMouse,mouse);
        }
        if (InputManager.getKey(RealmKey.Right) == KeyState.Press)
        {

            camera.turn(vec2(1,0));
            //getComponent!(ArcballCamera)().rotate(prevMouse,mouse);
        }
        else if (InputManager.getMouseButton(RealmMouseButton.ButtonRight) == KeyState.Press)
        {
            //getComponent!(ArcballCamera)().pan(mouse-prevMouse);
        }

        lastX = mouse.x;
        lastY = mouse.y;
        vec3 moveVector = vec3(0, 0, 0);
        if (InputManager.getKey(RealmKey.W) == KeyState.Press)
        {
            moveVector = camera.front * 0.05;
        }
        else if (InputManager.getKey(RealmKey.S) == KeyState.Press)
        {
            moveVector = camera.front * -0.05;
        }

        if (InputManager.getKey(RealmKey.A) == KeyState.Press)
        {
            moveVector = camera.front.cross(vec3(0, 1, 0)).normalized() * -0.05;
        }
        else if (InputManager.getKey(RealmKey.D) == KeyState.Press)
        {
            moveVector = camera.front.cross(vec3(0, 1, 0)).normalized() * 0.05;
        }
        camera.position += moveVector;
        //arcballcamera.pan(vec2(lastX,lastY),vec2(x,y));

    }

    void update()
    {

        processInput();

        updateComponents();
        camera.update();

    }

}