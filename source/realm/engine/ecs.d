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
        E entity = new E(uuid);
        //entity.construct(uuid);
        entity.start(t);
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
            foreach(entity; __traits(getMember,this,toLower(Type.mangleof)))
			{
                if(entity.active)
				{
                    entity.update();
                    entity.updateComponents();
				}
			}
            //mixin("foreach(entity; %s){entity.update();entity.updateComponents();}".format(toLower(Type.mangleof)));
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

enum string componentName(T) = T.mangleof;

mixin template RealmEntity(string eName, T...)
{

    private
    {
        import realm.engine.logging;
        import std.uni;
        import std.format;
        import realm.engine.graphics.material;
    }

    struct Components
    {
       
        static foreach (Type; T)
        {
            static assert(!isMaterial!(Type),"Materials cant be components");
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
    private bool _active;

    void construct(UUID id)
    {
        import core.memory :GC;
        import core.stdc.stdlib : malloc;
        import std.conv : emplace;
        
        this._id = id;
        _active = true;
        static foreach(Type; T)
		{
            static if(!__traits(isZeroInit,Type))
			{
				const (void)[] init = typeid(Type).initializer();
				void* ptr = malloc(init.length);
				ptr[0..init.length] = init[];
				__traits(getMember,this,componentName!(Type)) = cast(Type)ptr;
                GC.addRange(ptr.ptr,init.length);

			}



		}
    }

    this(UUID id)
	{
		import core.memory :GC;
        import core.stdc.stdlib : malloc;
        import std.conv : emplace;

        this._id = id;
        _active = true;
        static foreach(Type; T)
		{
            static if(componentName!(Type)[0] == 'C')
			{
                {
                    auto size= __traits(classInstanceSize,Type);
					//const (void)[] init = typeid(Type).initializer();
					auto memory = malloc(size)[0..size];
					GC.addRange(memory.ptr,size);
                    __traits(getMember,this,componentName!(Type)) = emplace!(Type)(memory);
				}
			}



		}
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
    @property active(bool value)
	{
        _active = value;
	}
    @property bool active()
	{
        return _active;
	}

}
