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

                static if (uniforms[uniform] == UserDataVarTypes.VECTOR )
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

enum bool isMaterial(T) = (__traits(hasMember, T, "shaderStorageBuffer") == true
            && __traits(hasMember, T, "textures") == true && __traits(hasMember, T, "layout") == true);
enum texturesMembers(T) = (__traits(allMembers, T.Textures));
enum texturesAttributes(T, alias Member) = (__traits(getAttributes,
            __traits(getMember, T.Textures, Member)));
enum isSampler(alias T) = (T == "Sampler");

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

    private SamplerObject!(TextureType.TEXTURE2D) textureArray;
    private static ShaderProgram program;
    this()
    {
        writeln(numMaterials);
        storageBufferPtr = &shaderStorageBuffer.ptr[numMaterials];
        materialIndex = numMaterials;
        numMaterials++;
        
        textureArray.create();

		
    }

    static void setShaderProgram(ShaderProgram sp)
	{
        program = sp;
	}

    void updateTextureArray()
	{
		int maxWidth = int.min;
        int maxHeight = int.min;
        static foreach (member; texturesMembers!(UniformLayout))
        {
            static foreach (attribute; texturesAttributes!(UniformLayout, member))
            {
                static if (isSampler!(attribute))
                {
                    Texture2D texture = __traits(getMember, textures, member);
                    if(cast(int)texture.width >maxWidth)
					{
                        maxWidth = texture.width;
					}
                    if(cast(int)texture.height > maxHeight)
					{
                        maxHeight = texture.height;
					}
                }
            }
        }
        textureArray.textureDesc = textures.settings;
        textureArray.width = maxWidth;
        textureArray.height = maxHeight;
        //textureArray.store(maxWidth,maxHeight);
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

    void activateTextures()
	{
        
        textureArray.setActive(materialIndex);
        program.setUniformInt(program.uniformLocation("atlasTextures[%d]".format(materialIndex)),materialIndex);
	}
    
    

    void writeTextureData()
    {
        int textureDepth = 0;
        static foreach (member; texturesMembers!(UniformLayout))
        {
            static foreach (attribute; texturesAttributes!(UniformLayout, member))
            {
                static if (isSampler!(attribute))
                {
                    Texture2D texture = __traits(getMember, textures, member);
                    if(texture !is null)
					{
                        //textureArray.uploadSubImage(0,0,0,texture.width,texture.height,texture.getImageData().ptr);
                        textureArray.uploadImage(0,0,texture.getImageData().ptr);
					}
                    else
					{
                        textureArray.uploadImage(0,0,null);
					}
                    
                    textureDepth++;
				}
			}
		}
    }

    static ulong materialId()
    {
        return (typeid(UniformLayout).toHash());
    }

}
