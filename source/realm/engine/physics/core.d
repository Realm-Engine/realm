module realm.engine.physics.core;
import bindbc.newton;

private
{
	import gl3n.math;
	import realm.engine.logging;
	import realm.engine.ecs;
}

private __gshared NewtonWorld* newtonWorld;


static this()
{
	loadNewton();
	newtonWorld = NewtonCreate();


}

public enum PhysicsShape
{
	Box,
	Sphere
}






static class Physics()
{
	
}

template PhysicsCollider(PhysicsShape shape)
{
	protected NewtonCollision* cs;
	private PhysicsBodyType bodyType;

}

class BoxCollider
{
	mixin PhysicsCollider!(PhysicsShape.Box);
	private PhysicsBody parentBody;
	

	void componentStart(E)(E parent)
	in
	{
		static assert(hasComponent!(E,PhysicsBody), E.stringof ~ " needs PhysicsBody component");
	}
	do
	{
		if(!hasComponent!(E,PhysicsBody))
		{
			Logger.LogError("GameObject needs phyiscs body");
		}
		Logger.LogInfo("Collider start");



	}

	
}

public enum PhysicsBodyType
{
	Dynamic,
	Kinematic
}

class PhysicsBody
{
	private PhysicsBodyType type;

}