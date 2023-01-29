module realm.engine.ecs;
import std.format;

import std.meta;
import std.ascii;


public
{
	import std.uuid;
}



mixin template ECS(C...)
{
    private
    {
        import realm.engine.logging;
        import std.uni;
        import std.format;
        import std.uuid;
        import std.meta;
    }

    public alias Components = AliasSeq!C;


    class ECS
	{
		struct ComponentLists
		{
			static foreach(ComponentType; C)
			{
				mixin("%s[UUID] %s;".format(ComponentType.stringof,ComponentType.mangleof));
			}
		}

		

		struct Entity
		{
			private ComponentLists* componentLists;
			private UUID id;
			
			@property ref Transform transform()
			{
				return getComponent!(Transform)();
			}
			

			this(ComponentLists* componentLists, UUID id)
			{
				this.componentLists = componentLists;
				this.id = id;
				
			}

			T addComponent(T,Args...)(Args args)
			{
				const int componentIndex = staticIndexOf!(T,Components);
				static if(componentIndex < 0)
				{
					static assert("Type " ~ T.stringof ~ " not a component");
				}
				
				T component = new T();
				component.eid =id;
				if(!__traits(isSame,T,Transform))
				{
					component.transform = getComponent!(Transform)();
				}
				
				mixin("(*componentLists).%s[id] = component;".format(T.mangleof));
				static if(__traits(hasMember,T,"componentStart"))
				{
					component.componentStart(args);
				}
				


				return component;



			}

			ref T getComponent(T)()
			{
				return __traits(getMember,componentLists,T.mangleof)[id];
			}



		}

		void update()
		{
			static foreach(ComponentType; Components)
			{
				foreach(component; __traits(getMember,componentLists,ComponentType.mangleof))
				{
					static if(__traits(hasMember,ComponentType,"componentUpdate"))
					{
						component.componentUpdate();
					}
				}
			}
		}



		ComponentLists componentLists;
		Entity createEntity()
		{
			Entity entity = Entity(&componentLists,randomUUID);
			Transform transform = entity.addComponent!(Transform)();
			
			return entity;
		}
		T* getEntityComponent(T)(UUID id)
		{
			T* component = id  in __traits(getMember,componentLists,T.mangleof);
			return component;
		}
	}

	alias Entity = ECS.Entity;


}
mixin template RealmComponent()
{
	import std.uuid;
	Transform transform;
	UUID eid;
	
	
}





