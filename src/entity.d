module realm.entity;
import realm.engine.core;


class Entity
{
	Mesh mesh;
	Transform transform;
	
	this(Mesh mesh, Transform transform)
	{
		this.mesh = mesh;
		this.transform = transform;
	}


}
