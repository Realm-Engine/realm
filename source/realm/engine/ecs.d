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
        pragma(msg,"Registering " ~ Type.stringof ~ " entity\nInternal name: "~  Type.mangleof ~ "\n");
        static assert(isEntity!(Type), Type.stringof ~ " is not a valid entity");
        mixin("private %s[UUID] %s;".format(Type.stringof, Type.mangleof));
    }
    E instantiate(E, Args...)(Args args)
    in 
	{
        static assert(isEntity!(E),"Object type to instantiate needs to be entity");
        static assert(__traits(hasMember,this,E.mangleof),"Entity type" ~ E.stringof ~ " has to be registered to be instantiated");
	}
    do
    {
        UUID uuid = randomUUID();
        E entity = new E(uuid);
        //entity.construct(uuid);
        entity.start(args);
        mixin("%s[uuid] = entity;".format(E.mangleof));
        return entity;
    }

    void updateEntities()
	{
        static foreach(Type; T)
		{
            foreach(entity; __traits(getMember,this,Type.mangleof))
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
        mixin("return " ~ E.mangleof ~ ".values;");
	}


}

enum bool isEntity(T) = (__traits(hasMember, T, "components") == true && __traits(hasMember,
            T, "setComponent") == true && __traits(hasMember, T, "getComponent") == true && __traits(hasMember,T,"update"));

mixin template RealmComponent()
{

    


     

   


}

enum string componentName(T) = T.mangleof;

enum bool hasComponent(E,C) = (__traits(hasMember,E.Components,C.mangleof));

mixin template RealmEntity(string eName, T...)
{

    alias parentType = __traits(parent,Components);
    
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


    }

	void updateComponents()
	{

		
		static foreach(Type; T)
		{
            static if(__traits(hasMember, Type,"componentUpdate" ))
			{
                pragma(msg, "Component " ~ Type.stringof ~ " update function registered");
                __traits(getMember,this,componentName!(Type)).componentUpdate!(parentType)(this);
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
        static foreach(Type; T)
		{
            static if(__traits(hasMember, Type,"componentStart" ))
			{
                pragma(msg, "Component " ~ Type.stringof ~ " start function registered");
                __traits(getMember,this,componentName!(Type)).componentStart!(parentType)(this);
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
