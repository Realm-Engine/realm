module realm.engine.graphics.material;
import realm.engine.graphics.core;
import realm.engine.graphics.graphicssubsystem;
import realm.engine.graphics.opengl;
import std.stdio;
import std.algorithm.sorting;
import std.range;
import gl3n.linalg;
import gl3n.math;
import realm.engine.core;
import realm.engine.logging;
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

                static if (uniforms[uniform] == UserDataVarTypes.VECTOR || uniforms[uniform] == UserDataVarTypes.TEXTURE2D )
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


enum bool isMaterial(T) = (__traits(hasMember, T, "shaderStorageBuffer") == true && __traits(hasMember, T, "textures") == true && __traits(hasMember, T, "layout") == true);
enum texturesMembers(T) = (__traits(allMembers, T.Textures));
enum texturesAttributes(T, alias Member) = (__traits(getAttributes, __traits(getMember, T.Textures, Member)));
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

    private SamplerObject!(TextureType.TEXTURE2D) textureAtlas;
    private static ShaderProgram program;
    private static Mesh*[] meshes;


    this()
    {
        writeln(numMaterials);
        storageBufferPtr = &shaderStorageBuffer.ptr[numMaterials];
        materialIndex = numMaterials;
        numMaterials++;
        
        textureAtlas.create();
        
        textureAtlas.slot = materialIndex;

		
    }

    SamplerObject!(TextureType.TEXTURE2D) getTextureAtlas()
	{
        return this.textureAtlas;
	}

    static void setShaderProgram(ShaderProgram sp)
	{
        program = sp;
	}

    static ShaderProgram getShaderProgram()
	{
        return program;
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

    static void bindShaderStorage()
	{
        shaderStorageBuffer.bindBase(1);
	}

    static void addMesh(Mesh* mesh)
	{
        meshes~= mesh;
	}

    static void useShaderProgram()
	{
        program.use();
	}

    void writeUniformData()
    {
        

        *storageBufferPtr = layout;

    }

    void activateTextures()
	{
        
        textureAtlas.setActive();
        program.setUniformInt(program.uniformLocation("atlasTextures[%d]".format(materialIndex)),materialIndex);
	}

    
    
    void packTextureAtlas()
	{
        textureAtlas.setActive();
        textureAtlas.textureDesc = textures.settings;
        Texture2D[] textures;
		int sumWidth = 0;
        int sumHeight = 0;
        vec4*[] tilingOffsets;
        static foreach (member; texturesMembers!(UniformLayout))
        {
            static foreach (attribute; texturesAttributes!(UniformLayout, member))
            {
                static if (isSampler!(attribute))
                {
                    
                    if(__traits(getMember, this.textures, member) !is null)
					{
                        writeln(member);
                        textures~= __traits(getMember, this.textures, member);
                        tilingOffsets ~= &__traits(getMember,this.layout,member);
                        sumWidth += __traits(getMember, this.textures, member).w;
                        sumHeight += __traits(getMember, this.textures, member).h;

					}
                    

				}
			}
		}
        
        int textureAtlasWidth = cast(int)(sumWidth * 1.5);
        int textureAtlasHeight = cast(int)(sumHeight * 1.5);
        Logger.LogInfo("%d %d",textureAtlasWidth,textureAtlasHeight);
        auto sorted = textures.sort!((t1, t2) => (t1.w * t1.h) > (t2.w * t2.h));
        int totalWidth = 0;
        int totalHeight = 0;
        int rowWidth = 0;
        int rowHeight = int.min;
        textureAtlas.store(textureAtlasWidth,textureAtlasHeight);
        
        foreach(index,texture; sorted.enumerate(0))
		{
WriteImage:
            if(texture.w + rowWidth < cast(int)textureAtlas.width)
			{
                

                textureAtlas.uploadSubImage(0,rowWidth,totalHeight,texture.w,texture.h,texture.buf8.ptr);
                

                vec4 tilingOffset;
                tilingOffsets[index].x = cast(float)texture.w / textureAtlas.width;
                tilingOffsets[index].y = cast(float)texture.h/ textureAtlas.height;
                tilingOffsets[index].z = cast(float)rowWidth / textureAtlas.width;
                tilingOffsets[index].w = cast(float)totalHeight/textureAtlas.height;
				if(cast(int)texture.h > rowHeight)
				{
                    rowHeight = texture.h;
				}
                rowWidth += texture.w;


			}
            else
            {
                totalHeight += rowHeight;
                rowWidth = 0;
                goto WriteImage;
			}


		}
       
	}
   

    static ulong materialId()
    {
        return (typeid(UniformLayout).toHash());
    }

}
