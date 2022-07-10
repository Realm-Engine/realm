module realm.engine.physics.core;

private
{
	import gl3n.math;
	import realm.engine.logging;
	import realm.engine.ecs;
	import realm.engine.core;
	import std.uuid;
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
		
		AABB transformAABB(AABB box, mat4 matrix)
		{
			vec3 aMin = box.min;
			vec3 aMax = box.max;
			vec3 translation = vec3(matrix[0][3],matrix[1][3],matrix[2][3]);
			vec3 bMin,bMax;
			bMax = bMin =  translation;
			mat3 transform = mat3(matrix);
			for(int i = 0; i < 3; i++)
			{
				for(int j = 0; j < 3; j++)
				{
					float a = transform[i][j] * aMin.value_ptr[j];
					float b = transform[i][j] * aMax.value_ptr[j];
					if(a < b)
					{
						bMin.vector[i] += a;
						bMax.vector[i] += b;
					}
					else
					{
						bMin.vector[i] += b;
						bMax.vector[i] += a;
					}
				}
			}
			AABB result = AABB(bMin,bMax);
			return result;
			


		}
		mat4 transform1 = colliders.getColliderTransformDelegates[body1]();
		mat4 transform2 = colliders.getColliderTransformDelegates[body2]();
		
		aabb1 = transformAABB(aabb1,transform1);
		aabb2 = transformAABB(aabb2,transform2);
		
		
		Debug.drawBox(aabb1.center,aabb1.extent,vec3(0));
		if(aabb1.intersects(aabb2))
		{
			
			if(body1 in colliders.lastTransforms)
			{
				mat4 lastTranslation = colliders.lastTransforms[body1].get_translation;
				mat4 currentTranslation = transform1;
				vec3 lastPosition = vec3(lastTranslation[0][3],lastTranslation[1][3],lastTranslation[3][3]);
				vec3 currentPosition = vec3(currentTranslation[0][3],currentTranslation[1][3],currentTranslation[3][3]);
				vec3 differnce = currentPosition - lastPosition;
				mat4 transInv = mat4.translation(differnce).inverse();
				if(differnce.magnitude > 0)
				{

					mat4 reverse = transform1.translate(-differnce);
					colliders.setColliderTransformDelegates[body1](  reverse );
				}
				
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
