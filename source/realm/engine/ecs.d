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

    private
    {
        import realm.engine.logging;
        import std.uni;
        import std.format;
        import std.uuid;
    }
    static foreach (Type; T)
    {
        pragma(msg,"Registering " ~ Type.stringof ~ " entity\nInternal name: "~  toLower(Type.mangleof) ~ "\n");
        static assert(isEntity!(Type), Type.stringof ~ " is not a valid entity");
        mixin("private %s[UUID] %s;".format(Type.stringof, toLower(Type.mangleof)));
    }
    E instantiate(E, T...)(T t)
    in 
	{
        static assert(isEntity!(E),"Object type to instantiate needs to be entity");
	}
    do
    {
        UUID uuid = randomUUID();
        E entity = new E(t);
        entity.construct(uuid);
        mixin("%s[uuid] = entity;".format(toLower(E.mangleof)));
        return entity;
    }
    E instantiate(E)(E e)
    in
	{
        static assert(isEntity!(E),"Object type to instantiate needs to be entity");
        static assert(__traits(hasCopyConstructor,E) == true, "Entity needs copy constructor to use this overload");
        static assert(__traits(isCopyable,E) == true,"Entity needs to be copyable to use this overload");
	}
    do
	{
        E entity = new E(e);
        UUID uuid = randomUUID();
		entity.construct(uuid);
        mixin("%s[uuid] = entity;".format(toLower(E.mangleof)));
        return entity;
	}
    void updateEntities()
	{
        static foreach(Type; T)
		{
            
            mixin("foreach(entity; %s){entity.update();entity.updateComponents();}".format(toLower(Type.mangleof)));
		}
	}
    E[] getEntities(E)()
	{
        mixin("return " ~ toLower(E.mangleof) ~ ".values;");
	}


}

enum bool isEntity(T) = (__traits(hasMember, T, "components") == true && __traits(hasMember,
            T, "setComponent") == true && __traits(hasMember, T, "getComponent") == true && __traits(hasMember,T,"update"));

mixin template RealmComponent(string cName)
{
    private string _name;
    @property name()
	{
        return _name;
	}
    @property name(string n)
	{
        _name =n;
	}
    

}

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
            pragma(msg,"Adding " ~ Type.stringof ~ " component to " ~ eName);  
            mixin("private %s %s;".format(Type.stringof, Type.mangleof));
			static if(!__traits(hasMember,Type,"componentUpdate"))
			{
				pragma(msg,"Warning: component " ~ Type.stringof ~ " does not have componentUpdate function and will not update automatically");
			}

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

        return __traits(getMember, components, C.mangleof);

    }

    void setComponent(C)(C value)
    {
        __traits(getMember, components, C.mangleof) = value;
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
