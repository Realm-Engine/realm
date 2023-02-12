module realm.engine.ecs.manager;

import core.stdc.stdlib;
import core.stdc.string;
import std.traits;
import realm.engine.logging;
import std.conv;
import realm.engine.core;
import std.string;
public
{
	import realm.engine.ecs.core;
}

static __gshared ECSManager ecsManager = void;


mixin template RealmComponent()
{
	Transform transform;
	Entity entity;
}

alias UpdateComponent = void delegate();

class ECSManager
{
	package ComponentInfo[size_t] componentMap;
	package ComponentList[] componentLists;
	private UpdateComponent[] componentUpdateFns;
	private Entity[] entities;
	static void initialize()
	{
		ecsManager = new ECSManager();
	}

	this()
	{

	}

	void registerComponent(T)()
	{
		ComponentInfo cInfo;
		cInfo.alignment = T.alignof;		
		cInfo.initSymbolLength = __traits(initSymbol,T).length;
		
		
		alias fullName = fullyQualifiedName!(T);
		size_t hash = fullName.hashOf;
		cInfo.hash = hash;
		componentMap[hash] = cInfo;
		info("Registering component %s", fullName.toStringz());
	}

	

	Entity createEntity()
	{
		return createEntity("Entity");
	}

	Entity createEntity(string name)
	{
		UUID id = randomUUID();
		Entity entity = new Entity();
		entity.eId = id;
		ComponentList componentList = new ComponentList();
		componentLists ~= componentList;
		entity.componentList = componentList;
		Transform transform = entity.addComponent!(Transform)();
		
		entity.name = name;
		entities ~= entity;
		return entity;



	}

	void addComponentUpdateFn(T)(T component)
	in
	{
		static assert(__traits(hasMember,component,"componentUpdate"),T.stringof ~ "does not have a componentUpdate() function");
	}
	do
	{
		componentUpdateFns ~= &component.componentUpdate;
	}

	void update()
	{
		foreach(updateFn ; componentUpdateFns)
		{
			updateFn();
		}
	}

	

	~this()
	{
		
	}



}