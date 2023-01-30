module realm.engine.animation.clip;
import glfw3.api;

struct KeyFrame(T)
{
	T value;
	float time;
}

class Clip(T, string Property)
{
	bool finished;
	KeyFrame!(T)[] keyFrames;
	string property;

	
	void addKeyFrame(KeyFrame!(T) key)
	{
		keyFrames~=key;
	}

}


