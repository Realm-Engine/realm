module realm.entity;
import realm.engine.core;
import realm.engine.graphics.material;
import realm.engine.ecs;
import std.format;
class Entity(Mat)
{

	mixin RealmEntity!(Transform, Mesh);

	static assert(isMaterial!(Mat));
	Mat material;

	
	this(Mesh mesh, Transform transform)
	{
		this.mesh = mesh;
		this.transform = transform;
		string name = typeid(Mat).toString();
		material = new Mat();
		
	}

	this(Mesh mesh)
	{
		this(mesh, new Transform);
	}


}
