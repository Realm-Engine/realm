module realm.engine.physics.collision;
private
{
	import gl3n.linalg;
	import realm.engine.ecs;
	import std.variant;
}




struct BoxShape
{
	vec3 center;
	vec3 size;


}


enum ColliderShape
{
	Box,
	Mesh
}

class SimpleCollider
{
	
	import realm.engine.core;
	import gl3n.aabb;
	private AABB bounds;
	mixin RealmComponent;
	private Transform parentTransform;
	private ColliderShape shapeType;
	this()
	{
		
	}

	void componentStart(E)(E parent)
	{

		
		static if(hasComponent!(E,Transform))
		{
			Logger.LogInfo("Parent has transform");
			parentTransform = parent.getComponent!(Transform);
		}
		


		//auto parent = getParent().get!(__traits(toType,parentTypeMangle));
		//TypeInfo parentType = parent.type;
		//string s = parentType.toString();
		//parentTransform = getParentComponent!(Transform)();
	}

	union
	{
		BoxShape boxCollider;
		Mesh* mesh;
	}

	@property shape(BoxShape shape)
	{
		boxCollider = shape;
		shapeType = ColliderShape.Box;
	}
	@property shape(Mesh* mesh)
	{
		mesh = mesh;
		shapeType = ColliderShape.Mesh;
	}

	private void calculateBounds()
	{
		if(shapeType == ColliderShape.Mesh)
		{
			
		}
	}

	void componentUpdate(E)(E parent)
	{
		calculateBounds();

	}

	

}
