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
        struct UserData
        {
            static foreach (uniform; uniforms.keys)
            {

                //string type;
                static if (uniforms[uniform] == UserDataVarTypes.FLOAT)
                {
                    mixin("%s %s;".format("float", uniform));
                }

                static if (uniforms[uniform] == UserDataVarTypes.VECTOR)
                {
                    mixin("%s %s;".format("vec4", uniform));
                }

                //mixin("%s %s;".format("vec3",uniform));
            }
        }


        struct Textures
        {
            TextureDesc settings;
            static foreach (uniform; uniforms.keys)
            {
                static if (uniforms[uniform] == UserDataVarTypes.TEXTURE2D)
                {
                    
                    mixin("@(\"Sampler\") %s %s;".format("Texture2D", uniform));
                }
            }
        }

        
    }

}

class Material(UserDataVarTypes[string] uniforms)
{
    import std.format;
    import std.stdio;

    mixin MaterialLayout!(uniforms);
    UniformLayout.Textures textures;
    UniformLayout.UserData layout;
    alias layout this;

    static ShaderStorage!(UniformLayout.UserData, BufferUsage.MappedWrite) shaderStorageBuffer;

    private static uint numMaterials = 0;
    private uint materialIndex = 0;
    private UniformLayout.UserData* storageBufferPtr;
    private SamplerObject!(TextureType.TEXTURE2DARRAY) textureArray;
  
    

    this()
    {
        writeln(numMaterials);
        storageBufferPtr = &shaderStorageBuffer.ptr[numMaterials];
        materialIndex = numMaterials;
        numMaterials++;
        textureArray.create();
        
        
        samplerNames();
        

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
    static string[] samplerNames()
	{
        string[] samplerNames;
		static foreach(member;__traits(allMembers,UniformLayout.Textures))
		{
           
			static foreach(attribute; __traits(getAttributes,__traits(getMember,UniformLayout.Textures,member)))
			{
                
				static if(attribute ==  "Sampler")
				{
					samplerNames ~= member;
					writeln(member);
				}
			}
		}
        return samplerNames;
	}

    void writeUniformData()
    {
        *storageBufferPtr = layout;

    }
    
    void writeTextureData()
	{
        


	}

	static ulong materialId()
	{
		return (typeid(UniformLayout).toHash());
	}

     
}

enum bool isMaterial(T) = (__traits(hasMember, T, "shaderStorageBuffer") == true && __traits(hasMember,T,"textures") == true && __traits(hasMember,T,"layout") == true);

