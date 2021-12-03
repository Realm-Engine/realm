module realm.entity;
import realm.engine.core;


class Entity
{
	Mesh mesh;
	Transform transform;
	alias transform this;
	this(Mesh mesh, Transform transform)
	{
		this.mesh = mesh;
		this.transform = transform;
		
	}

	this(Mesh mesh)
	{
		this.mesh = mesh;
		this.transform = new Transform;
	}


}
