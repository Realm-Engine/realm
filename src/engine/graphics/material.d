module realm.engine.graphics.material;
import realm.engine.graphics.core;


struct UniformLayout
{

	string[UserDataVarTypes] uniforms;


}


mixin template MaterialLayout(UserDataVarTypes[string] uniforms)
{
	import std.format;
	import gl3n.linalg;
	struct UniformLayout
	{
		static foreach(uniform;uniforms.keys)
		{
		
			//string type;
			static if(uniforms[uniform] == UserDataVarTypes.FLOAT)
			{
				mixin("%s %s;".format("float",uniform));
			}

			static if(uniforms[uniform] == UserDataVarTypes.VECTOR)
			{
				mixin("%s %s;".format("vec3",uniform));
			}

			//mixin("%s %s;".format("vec3",uniform));
		}
	}

	

}

class Material(UserDataVarTypes[string] uniforms)
{
	mixin MaterialLayout!(uniforms);

	UniformLayout layout;

	alias layout this;


}