module realm.engine.ecs;

const MAX_COMPONENTS = 126;

alias ComponentRegistry = TypeInfo[ulong];


class ComponentManager
{
	static ComponentRegistry registry;
	static void RegisterComponent(T)()
	{
		registry[typeid(T).getHash()] = typeid(T);
	}


}