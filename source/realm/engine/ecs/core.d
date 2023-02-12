module realm.engine.ecs.core;
public
{
	import std.traits;
	import std.uuid;
}
import realm.engine.ecs.manager;
import core.stdc.stdlib;
import core.stdc.string;
import std.conv;
import realm.engine.core;
import std.typecons;
package ptrdiff_t alignTo(ref size_t ptr, size_t alignment)
{
	size_t initial = ptr;
	size_t mod = ptr & (alignment - 1);
	if(mod != 0)
	{
		ptr+=alignment - mod;
	}
	return initial - ptr;
}

struct ComponentInfo
{
	size_t alignment;
	size_t initSymbolPtr;
	size_t initSymbolLength;
	size_t hash;

	

}


class ComponentListNode
{
	ComponentListNode next;

	
	ComponentInfo cInfo;
	void* componentData;
		//ComponentListNode* next;
	

}


class ComponentList
{
	
	size_t length;
	ComponentListNode head;

	this()
	{
		head = new ComponentListNode;
		head.next = null;
	}

	void add(ComponentInfo cInfo, void* data)
	{
		ComponentListNode node = new ComponentListNode();
		node.cInfo = cInfo;
		node.componentData = data;
		ComponentListNode current = head;
		while(current.next !is null)
		{
			current = current.next;
		}
		current.next = node;
		node.next = null;
		length++;


	}
}

class Entity
{
	
	UUID eId;
	ComponentList componentList;
	private void[] componentBuffer;
	string name;
	@property transform()
	{
		return getComponent!(Transform);
	}

	T addComponent(T,Args...)(Args args)
	{
		alias fullName = fullyQualifiedName!(T);
		size_t hash = fullName.hashOf;
		ComponentInfo cInfo = ecsManager.componentMap[hash];
		//size_t componentPtr = allocateComponent!(T)(cInfo,args);
		void[] componentMem = malloc(cInfo.initSymbolLength)[0..cInfo.initSymbolLength];
		componentList.add(cInfo,componentMem.ptr);
		static if(is(T==class))
		{
			auto support = cast(T)componentMem.ptr;
			//T component = cast(T)(support);
			auto component = emplace!T(componentMem);
			component.transform = getComponent!(Transform);
			component.entity = this;
			static if(__traits(hasMember,component,"componentStart"))
			{
				component.componentStart(args);
			}

			static if(__traits(hasMember,component,"componentUpdate"))
			{
				ecsManager.addComponentUpdateFn!(T)(component);
			}
			
			return component;
		}
		else
		{
			
			T* component = cast(T*)componentMem.ptr;
			emplace!(T)(component);
			return *component;
		}



	}

	


	T getComponent(T)() if(is(T==class))
	{
		T component;
		alias fullName = fullyQualifiedName!(T);
		size_t hash = fullName.hashOf;
		ComponentListNode current = componentList.head;
		while(current !is null)
		{
			if((current).cInfo.hash == hash)
			{

				return (cast(T)(current.componentData));
			}
			current = current.next;

		}
		return null;
	}

	T* getComponent(T)() if(is(T==struct))
	{
		
		alias fullName = fullyQualifiedName!(T);
		size_t hash = fullName.hashOf;
		ComponentListNode current = componentList.head;
		while(current !is null)
		{
			if((current).cInfo.hash == hash)
			{
				
				return (cast(T*)&(current.componentData));
			}
			current = current.next;

		}
		return null;
	}

	~this()
	{
		info("Entity dealloc");
	}

}


