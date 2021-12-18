module realm.player;
import realm.engine.core;
import realm.engine.ecs;

class Player
{
	private Camera* camera;
	

	this(Camera* cam)
	{
		this.camera = cam;
	}

}