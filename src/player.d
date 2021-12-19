module realm.player;
import realm.engine.core;
import realm.engine.ecs;
import realm.engine.input;
import realm.engine.logging;

import std.stdio;
class Player
{
	private Camera* camera;
	
	mixin RealmEntity!(Transform);

	this(Camera* cam)
	{
		this.camera = cam;
		transform = new Transform();
	}

	void update()
	{
		vec3 moveVector = vec3(0,0,0);
		if(InputManager.getKey(RealmKey.W) == KeyState.Press)
		{
			moveVector = camera.front * 0.05;
		}
		else if(InputManager.getKey(RealmKey.S) == KeyState.Press)
		{
			moveVector = camera.front * -0.05;
		}
		
		if(InputManager.getKey(RealmKey.A) == KeyState.Press)
		{
			moveVector = camera.right * -0.05;
		}
		else if(InputManager.getKey(RealmKey.D) == KeyState.Press)
		{
			moveVector  = camera.right * 0.05;
		}


		camera.position  = camera.position + moveVector;
		updateComponents();

	}

}