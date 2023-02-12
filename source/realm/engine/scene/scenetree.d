module realm.engine.scene.scenetree;
import realm.engine.core;
import realm.engine.layer3d;
import realm.engine.memory;
import realm.engine.container.queue;
import std.uuid;
import realm.engine.ecs;
class Scene
{

	

	ECSManager ecs;
	private Entity root;
	private RealmArenaAllocator allocator;
	uint sceneSize;
	this(ECSManager ecs)
	{
		allocator = new RealmArenaAllocator(__traits(classInstanceSize,Transform));
		root = ecs.createEntity("root");
		this.ecs = ecs;
		sceneSize = 1;
	}

	Transform getSceneRoot()
	{
		return root.transform;
	}



	T findComponent(T)() if(is(T==class)) 
	{
		T result = null;
		foreach(child; root.transform)
		{
		    
		    if(child.entity.getComponent!(T)() !is null)
		    {
				//info("%s",child.eid.toString());
		        result = child.entity.getComponent!(T)();
		        break;
		    }
		
		}
		return result;
		
	}
	


	void add(Entity entity)
	{

		root.transform.addChild(entity.getComponent!(Transform)());
		sceneSize ++;
		sceneSize += entity.transform.getChildren.length;
		



	}



	void draw(Layer3D layer)
	{

		bool[UUID] visited;
		allocator.resize(((__traits(classInstanceSize,Transform) * sceneSize)) *2 );
		Queue!(Transform) queue = new Queue!(Transform)(sceneSize,allocator);
		visited[root.eId] = true;
		queue.enqueue(root.transform);
		while(!queue.empty)
		{
			Transform transform = queue.dequeue();


			MeshRenderer meshRenderer = transform.entity.getComponent!(MeshRenderer)();
			if(meshRenderer !is null)
			{
				layer.drawTo(meshRenderer.mesh,meshRenderer.material,transform);
			}

			if(transform.getParent() !is null)
			{
				foreach(Transform sibling;transform.getParent().getChildren())
				{
					if(sibling.entity.eId != transform.entity.eId)
					{
						queue.enqueue(sibling);
						visited[sibling.entity.eId] =  true;
					}
				}

			}
			foreach(Transform child; transform.getChildren())
			{
				queue.enqueue(child);
				visited[child.entity.eId] =  true;
			}

		}

		allocator.deallocate();


	}


}