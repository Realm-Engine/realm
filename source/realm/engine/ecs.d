module realm.engine.ecs;
import std.format;

import std.meta;
import std.ascii;
public
{
    import std.uuid;
}

mixin template EntityRegistry(T...)
{
	
	class EntityManager
    {
        private
		{
			import realm.engine.logging;
			import std.uni;
			import std.format;
			import std.uuid;
		}
        static foreach (Type; T)
        {
            
            static assert(isEntity!(Type),Type.stringof ~ " is not a valid entity");
            mixin("private %s[UUID] %ss;".format(Type.stringof, toLower(Type.mangleof)));
		}
        E instantiate(E, T...)(T t)
		in(isEntity!(E))
		{
            UUID uuid = randomUUID();
            E entity = new E(t);
            entity.construct(uuid);
            mixin("%ss[uuid] = entity;".format(toLower(E.mangleof)));
            return entity;
		}

	}

    


}
enum bool isEntity(T) = (__traits(hasMember,T,"components") == true
						 && __traits(hasMember,T,"setComponent")== true
						 && __traits(hasMember,T,"getComponent")== true);
mixin template RealmEntity(string eName, T...)
{
    
    private
    {
        import realm.engine.logging;
        import std.uni;
        import std.format;
    }

    struct Components
    {
        static foreach (Type; T)
        {
            

            mixin("private %s %s;".format(Type.stringof, Type.mangleof));
            
        }
        
	    
        

        void updateComponents()
        {

            static foreach (componentMember; (__traits(allMembers, Components)))
            {
                
                static if (__traits(compiles, __traits(getMember, this,
                        componentMember).componentUpdate()))
                {
                    
                    __traits(getMember, this, componentMember).componentUpdate();
                }
            }
        }   
    }

    Components components;
    alias components this;


   	ref C getComponent(C)()
	{
        
		return __traits(getMember,components,C.mangleof);

	}

	void setComponent(C)(C value)
	{
		__traits(getMember,components,C.mangleof) = value;
	}


    private string _entityName = eName;
    private UUID _id;

    void construct(UUID id)
	{
        this._id = id;
	}

    @property id()
	{
        return _id;
	}
    @property entityName()
	{
        return _entityName;
	}
    @property entityName(string value)
	{
        _entityName = value;
	}
    


    
}
