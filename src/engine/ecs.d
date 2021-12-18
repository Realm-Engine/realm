module realm.engine.ecs;
import std.format;
const MAX_COMPONENTS = 126;
import std.meta;
import std.ascii;


mixin template RealmEntity(T...)
{
	import std.uni;
	struct Components
	{
		static foreach(Type; T)
		{
			
			mixin("%s %s;".format(Type.stringof, toLower(Type.stringof) ));
		}
	}

	Components components;
	alias components this;


}