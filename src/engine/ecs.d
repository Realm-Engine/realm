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
            static assert(isEntity!(Type));
            mixin("private %s[UUID] %ss;".format(Type.stringof, toLower(Type.mangleof)));
		}
        E instantiate(E)()
		in(isEntity!(E))
		{
            UUID uuid = randomUUID();
            E entity = new E(uuid);
            mixin("%ss[uuid] = entity;".format(toLower(E.mangleof)));
            entity.start();
            return entity;
		}

	}

    


}
enum bool isEntity(T) = (__traits(hasMember,T,"components") == true
						 && __traits(hasMember,T,"setComponent")== true
						 && __traits(hasMember,T,"getComponent")== true
						 && __traits(hasMember,T,"start"));
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
            

            mixin("private %s %s;".format(Type.stringof, toLower(Type.stringof)));
            
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
        
		return __traits(getMember,components,toLower(C.stringof));

	}

	void setComponent(C)(C value)
	{
		__traits(getMember,components,toLower(C.stringof)) = value;
	}


    private string _entityName = eName;
    private UUID _id;
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
