module realm.engine.ecs;
import std.format;

const MAX_COMPONENTS = 126;
import std.meta;
import std.ascii;



mixin template RealmEntity(T...)
{
    private
    {
        import realm.engine.logging;
        import std.uni;
        import std.format;
    }

    struct Components
    {
        enum getComponents = (__traits(allMembers, Components));
        static foreach (Type; T)
        {

            mixin("private %s %s;".format(Type.stringof, toLower(Type.stringof)));
        }

        void updateComponents()
        {

            static foreach (componentMember; getComponents)
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
	C getComponent(C)()
	{
		return __traits(getMember,components,toLower(C.stringof));

	}
}
