module realm.engine.scene.scenetree;
import realm.engine.core;
import realm.engine.layer3d;
import realm.engine.memory;
import realm.engine.container.queue;
import std.uuid;
//import realm.engine.ecs;
class Scene(ECS)
{

	private ECS ecs;


	private Transform root;
	private RealmArenaAllocator allocator;
	uint sceneSize;
	this(ECS ecs)
	{
		allocator = new RealmArenaAllocator(__traits(initSymbol,Transform).length * 100);
		root = new Transform();
		this.ecs = ecs;
		sceneSize = 1;
	}

	Transform getSceneRoot()
	{
		return root;
	}



	T* findComponent(T)()
	{
		T* result = null;
		foreach(child; root)
		{
			
			if(ecs.getEntityComponent!(T)(child.eid) !is null)
			{
				//Logger.LogInfo("%s",child.eid.toString());
				result = ecs.getEntityComponent!(T)(child.eid);
				break;
			}

		}
		return result;
		//return result;
	}


	void add(ECS.Entity entity)
	{

		root.addChild(entity.getComponent!(Transform)());
		sceneSize ++;
		sceneSize += entity.transform.getChildren.length;
		



	}



	void draw(Layer3D layer)
	{

		bool[UUID] visited;
		Queue!(Transform) queue = new Queue!(Transform)(sceneSize,allocator);
		visited[root.eid] = true;
		queue.enqueue(root);
		while(!queue.empty)
		{
			Transform entity = queue.dequeue();


			MeshRenderer* meshRenderer = ecs.getEntityComponent!(MeshRenderer)(entity.eid);
			if(meshRenderer !is null)
			{
				layer.drawTo((*meshRenderer).mesh,(*meshRenderer).material,entity);
			}

			if(entity.getParent() !is null)
			{
				foreach(Transform sibling;entity.getParent().getChildren())
				{
					if(sibling.eid != entity.eid)
					{
						queue.enqueue(sibling);
						visited[sibling.eid] =  true;
					}
				}

			}
			foreach(Transform child; entity.getChildren())
			{
				queue.enqueue(child);
				visited[child.eid] =  true;
			}

		}

		allocator.deallocate();


	}


}