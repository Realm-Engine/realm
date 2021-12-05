module realm.engine.graphics.material;
import realm.engine.graphics.core;
import realm.engine.graphics.graphicssubsystem;
import realm.engine.graphics.opengl;
import std.stdio;

mixin template MaterialLayout(UserDataVarTypes[string] uniforms)
{
	import std.format;
	import gl3n.linalg;
	
	@("MaterialLayout")
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
				mixin("%s %s;".format("vec4",uniform));
			}

			//mixin("%s %s;".format("vec3",uniform));
		}

		static ulong materialId(){
			return (typeid(UniformLayout).toHash());
		}
		
		

	}

	UniformLayout layout;
	
	

}


class Material(UserDataVarTypes[string] uniforms)
{
	import std.stdio;
	mixin MaterialLayout!(uniforms);
	alias layout this;
	static ShaderStorage!(UniformLayout,BufferUsage.MappedWrite) shaderStorageBuffer;
	private static uint numMaterials = 0;
	private UniformLayout* storageBufferPtr;
	this()
	{
		writeln(numMaterials);
		storageBufferPtr = &shaderStorageBuffer.ptr[numMaterials];
		numMaterials++;

	}

	static void reserve(size_t numItems)
	{
		shaderStorageBuffer.store(numItems);
	}
	
	static void initialze()
	{
		shaderStorageBuffer.create();
		shaderStorageBuffer.bindBase(1);

	}

	void writeUniformData()
	{
		*storageBufferPtr = layout;

	}

}
enum bool isMaterial(T) = (__traits(hasMember,T,"shaderStorageBuffer") == true);

