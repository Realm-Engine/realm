module realm.engine.physics.core;
import bindbc.newton;

private
{
	import gl3n.math;
	import realm.engine.logging;
	import realm.engine.ecs;
	import realm.engine.core;
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

class PhysicsBody
{
	PhysicsBodyType type;
	private NewtonBody physicsBody;
	private Transform transform;
	private mat4 bodyOffset;
	private NewtonCollision* collision;
	this(PhysicsBodyType type)
	{
		this.type = type;
	}
	this()
	{
		type = PhysicsBodyType.Dynamic;
	}


	NewtonCollision* createBox(AABB bounds)
	{
		NewtonCollision* collision = NewtonCreateBox(newtonWorld,bounds.extent.x,bounds.extent.y,bounds.extent.z,0,bodyOffset.value_ptr);
		return collision;
	}

	void componentStart(E)(E parent)
	in
	{
		static assert(hasComponent!(E,Transform),"Physics bodies request entities to have a Transform Component");
	}
	do
	{
	
		AABB bounds = parent.getComponent!(Mesh).getWorldBounds();
		switch(type)
		{
			case PhysicsBodyType.Kinematic:
				collision = createBox(bounds);
				break;
			default:
				Logger.LogError("Unknown body type");
		}
	}

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

