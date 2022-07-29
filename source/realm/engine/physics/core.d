module realm.engine.physics.core;

private
{
	import gl3n.math;
	import realm.engine.logging;
	import realm.engine.ecs;
	import realm.engine.core;
	import std.uuid;
	import gl3n.plane;
}


__gshared PhysicsWorld physicsWorld;

static this()
{
	physicsWorld = new PhysicsWorld();

}

public enum PhysicsShape
{
	Box,
	Sphere
}


struct BoxCollider
{
	AABB bounds;
	vec3 center;
	void setSize(float x, float y, float z)
	{
		vec3 min = vec3(0) + center;
		vec3 max = vec3( x, y, z) + center;
		bounds = AABB(min,max);
		
	}

}

struct MeshCollider
{
	Mesh* mesh;
	vec3 center;
	AABB bounds;
	void componentStart(E)(E parent)
	in
	{
		static assert(hasComponent!(E,Mesh),"Mesh collider requires parent to have attached mesh");
	}
	do
	{
		mesh = &(parent.getComponent!(Mesh)());
		bounds = mesh.getLocalBounds();

	}


}

class PhysicsWorld
{
	alias GetColliderTransform = mat4 delegate();
	alias SetColliderTransform = void delegate(mat4);
	struct Colliders
	{
		UUID[] ids;
		AABB[UUID] boundingBoxes;
		GetColliderTransform[UUID] getColliderTransformDelegates;
		SetColliderTransform[UUID] setColliderTransformDelegates;
		
		mat4[UUID] lastTransforms;
		
		PhysicsBody[UUID] physicsBodies;
		
	}

	alias Collision = Tuple!(UUID,UUID);
	struct CollisionReports
	{
		Collision[] collisions; 
	}

	private Colliders colliders;
	private CollisionReports reports;
	
	private void reportCollision(UUID mainBody, UUID collidingBody)
	{
		reports.collisions ~= Collision(mainBody,collidingBody);
	}

	public UUID createCollider(AABB aabb, GetColliderTransform getTransformFunc,SetColliderTransform setTransformFunc,PhysicsBody physicsBody)
	{
		UUID uuid = randomUUID();
		colliders.ids ~= uuid;
		colliders.boundingBoxes[uuid] = aabb;
		colliders.getColliderTransformDelegates[uuid] = getTransformFunc;
		colliders.setColliderTransformDelegates[uuid] = setTransformFunc;
		colliders.physicsBodies[uuid] = physicsBody;
		Logger.LogInfo("New collider: %s", uuid.toString());
		return uuid;
	}
	
	private bool checkCollision(UUID body1, UUID body2)
	{
		import realm.engine.debugdraw;
		AABB aabb1 = colliders.boundingBoxes[body1];
		AABB aabb2 = colliders.boundingBoxes[body2];
		
		
		mat4 transform1 = colliders.getColliderTransformDelegates[body1]();
		mat4 transform2 = colliders.getColliderTransformDelegates[body2]();
		
		aabb1 = aabbTransformWorldSpace(aabb1,transform1);
		aabb2 = aabbTransformWorldSpace(aabb2,transform2);
		
		
		
		vec3 distance = aabb2.center - aabb1.center;
		distance.normalize();
		vec3 closestPoint = distance * aabb2.center;
		//closestPoint += aabb2.half_extent();
		
		if(aabb1.intersects(aabb2))
		{
			
			
			

			//Plane collisionPlane = Plane(distance,)
			if(body1 in colliders.lastTransforms)
			{
				
				mat4 lastTranslation = colliders.lastTransforms[body1];
				colliders.setColliderTransformDelegates[body1](  lastTranslation );
				
				
			}
			
			
			
			return true;
		}
		
		
		return false;

		



		

	}


	void tick(float dt)
	{
		import std.algorithm.setops;
		auto collisionChecks = cartesianProduct(colliders.ids,colliders.ids);
		reports.collisions.length = 0;
		foreach(collisionCheck; collisionChecks)
		{
			UUID body1 = collisionCheck[0];
			UUID body2 = collisionCheck[1];
			if(body1 != body2 && colliders.physicsBodies[body1].active && colliders.physicsBodies[body2].active)
			{
				if(checkCollision(body1,body2))
				{
					reportCollision(body1,body2);
				}
			}
			
		}
		foreach(id; colliders.ids)
		{
			colliders.lastTransforms[id] = colliders.getColliderTransformDelegates[id]();
		}
		
	}

	UUID[] getCollidingBodies(UUID collider)
	{
		UUID[] bodies;
		foreach(collision; reports.collisions)
		{
			if(collision[0] == collider)
			{
				bodies ~= collision[1];
			}
		}
		return bodies;
	}

	public PhysicsBody getPhysicsBody(UUID id)
	{
		return colliders.physicsBodies[id];
	}

}


 
struct CollisionInfo
{
	union 
	{
		bool empty;
		
		public PhysicsBody collidingBody;
		
	}


}

class PhysicsBody
{
	import std.variant;
	private Transform transform;
	private mat4 bodyOffset;
	private UUID bodyId;
	private Variant parentVariant;
	public bool active;
	this()
	{
		
	}


	

	void componentStart(E)(E parent)
	in
	{
		static assert(hasComponent!(E,Transform),"Physics bodies request entities to have a Transform Component");
	}
	do
	{
		AABB bounds;
		static if(hasComponent!(E,MeshCollider))
		{
			bounds = parent.getComponent!(MeshCollider).bounds;
		}
		else if(hasComponent!(E,BoxCollider))
		{
			bounds = parent.getComponent!(BoxCollider).bounds;
		}
		
		transform = parent.getComponent!(Transform)();
		bodyId = physicsWorld.createCollider(bounds,&transform.transformation,&transform.transformation,this);
		parentVariant = parent;
		active = true;
		

	}

	public Variant getParentObject()
	{
		return parentVariant;
	}

	public PhysicsBody[] getCollisions()
	{
		auto collidingBodies = physicsWorld.getCollidingBodies(bodyId);
		PhysicsBody[] collisions;
		foreach(collidingBody; collidingBodies)
		{
			
			
			
			collisions ~= physicsWorld.getPhysicsBody(collidingBody);

		}
		return collisions;
	}

	


}
