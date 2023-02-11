module realm.engine.ecs.manager;

import core.stdc.stdlib;
import core.stdc.string;
import std.traits;
import realm.engine.logging;
import std.conv;
import realm.engine.core;
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
	package void[] componentInitSymbolBuffer;
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

		size_t initSymbolPtr = storeInitSymbol(__traits(initSymbol,T),cInfo.alignment);
		cInfo.initSymbolPtr = initSymbolPtr;
		
		alias fullName = fullyQualifiedName!(T);
		size_t hash = fullName.hashOf;
		cInfo.hash = hash;
		componentMap[hash] = cInfo;
		Logger.LogInfo("Registering component %s", fullName);
	}

	private size_t storeInitSymbol(const void[] symbol,size_t alignment)
	{
		size_t length = symbol.length;
		

		size_t symbolPtr = componentInitSymbolBuffer.length;
		ptrdiff_t alignDiff = alignTo(symbolPtr,alignment);
		if(componentInitSymbolBuffer.length == 0)
		{
			componentInitSymbolBuffer = (malloc(length))[0..length];
		}
		else
		{
			componentInitSymbolBuffer = (realloc(componentInitSymbolBuffer.ptr,length +symbolPtr))[0..length +componentInitSymbolBuffer.length];
		}

		memcpy(&componentInitSymbolBuffer[symbolPtr],&symbol,length);
		return symbolPtr;
		

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
		free(componentInitSymbolBuffer.ptr);
	}



}