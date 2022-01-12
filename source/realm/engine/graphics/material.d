module realm.engine.graphics.material;
import realm.engine.graphics.core;
import realm.engine.graphics.graphicssubsystem;
import realm.engine.graphics.opengl;
import std.stdio;
import std.algorithm.sorting;
import std.algorithm;
import std.range;
import gl3n.linalg;
import gl3n.math;
import realm.engine.core;
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
                    mixin("%s %s;".format("float",(uniform~"packing")));
                }

                static if (uniforms[uniform] == UserDataVarTypes.VECTOR || uniforms[uniform] == UserDataVarTypes.TEXTURE2D)
                {
                    mixin("%s %s;".format("vec4", uniform));
                }
            }
        }

        struct Textures
        {
            TextureDesc settings;
            static foreach (uniform; uniforms.keys)
            {
                static if (uniforms[uniform] == UserDataVarTypes.TEXTURE2D && !overrideTexturePacking)
                {

                    mixin("@(\"Texture\") %s %s;".format("Texture2D", uniform));
                }

            }
        }

    }

}


enum bool isMaterial(T) = (__traits(hasMember, T, "shaderStorageBuffer") == true && __traits(hasMember, T, "textures") == true && __traits(hasMember, T, "layout") == true);
enum texturesMembers(T) = (__traits(allMembers, T.Textures));
enum texturesAttributes(T, alias Member) = (__traits(getAttributes, __traits(getMember, T.Textures, Member)));
enum isTexture(alias T) = (T == "Texture");
class Material(UserDataVarTypes[string] uniforms = [],int order = 0, bool overrideTexturePacking = false)
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
    private static uint reservedVertices;
    private static uint reservedElements;
    
    private bool shadows;
    static int getOrder()
    {
        return order;
    }

    static uint getNumMaterialInstances()
	{
        return numMaterials;
	}

   

    this()
    {
        
        storageBufferPtr = &shaderStorageBuffer.ptr[numMaterials];
        materialIndex = numMaterials;
        numMaterials++;
        if(texturesMembers!(UniformLayout).length >1 )
		{
            textureAtlas.create();
		}
        if(overrideTexturePacking)
		{
            textureAtlas.create();
		}

        
        textureAtlas.slot = materialIndex + 3;
        shadows = true;
		
    }


    void writeUniformData()
    {
        
        Logger.Assert(storageBufferPtr !is null, "Shader storage buffer ptr is null");
       
        *storageBufferPtr = layout;
        
        

    }

        
    void packTextureAtlas()
    in
	{
	    assert(!overrideTexturePacking,"Cannot call if packing texture atlas is done manually");
	}
    do
	{
        import std.math;
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
                static if (isTexture!(attribute))
                {
                    
                    if(__traits(getMember, this.textures, member) !is null)
					{
                       
                        textures~= __traits(getMember, this.textures, member);
                        tilingOffsets ~= &__traits(getMember,this.layout,member);
                        sumWidth += __traits(getMember, this.textures, member).w;
                        sumHeight += __traits(getMember, this.textures, member).h;

					}
                    

				}
			}
		}
        auto sortedTextures = textures.sort!((t1, t2) => (t1.w * t1.h) > (t2.w * t2.h));
        int nextMultiple(int num, int multiple)
		{
           
            if(multiple == 0)
			{
                return num;
			}
            int remainder = abs(num) % multiple;
            if(remainder == 0)
			{
                return num;
			}
            if(num < 0)
			{
                return -(abs(num) - remainder);
			}
            return num + multiple - remainder;
		}
        int textureAtlasWidth = nextMultiple(sumWidth,1024);
        int textureAtlasHeight = nextMultiple(sumHeight,1024);

      
        int totalWidth = 0;
        int totalHeight = 0;
        int rowWidth = 0;
        int rowHeight = int.min;
        textureAtlas.store(textureAtlasWidth,textureAtlasHeight);
        vec4 calculateTilingOffset(int width, int height)
        {
            vec4 tilingOffset;
            tilingOffset.x = cast(float)width / textureAtlas.width;
            tilingOffset.y = cast(float)height / textureAtlas.height;
            tilingOffset.z = cast(float)rowWidth / textureAtlas.width;
            tilingOffset.w = cast(float)totalHeight / textureAtlas.height;
            return tilingOffset;
        }
       

        foreach(index,texture; sortedTextures.enumerate(0))
		{
WriteImage:
            if(texture.w + rowWidth <= cast(int)textureAtlas.width)
			{
                
                tilingOffsets[index].x = cast(float)texture.w / textureAtlas.width;
                tilingOffsets[index].y = cast(float)texture.h/ textureAtlas.height;
                tilingOffsets[index].z = cast(float)rowWidth / textureAtlas.width;
                tilingOffsets[index].w = cast(float)totalHeight/textureAtlas.height;
                textureAtlas.uploadSubImage(0,rowWidth,totalHeight,texture.w,texture.h,texture.buf8.ptr);

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

    void updateAtlas(IFImage image, vec4* tilingOffset)
	{
        tilingOffset.x = cast(float)image.w / textureAtlas.width;
        tilingOffset.y = cast(float)image.h / textureAtlas.height;
       
        textureAtlas.uploadSubImage(0,cast(int)tilingOffset.z * textureAtlas.width,cast(int)tilingOffset.w * textureAtlas.height,image.w,image.h,image.buf8.ptr);
	}

    void updateAtlas(Texture2D texture, vec4 tilingOffset)
    {
        textureAtlas.uploadSubImage(0,cast(int)tilingOffset.z * textureAtlas.width,cast(int)tilingOffset.w * textureAtlas.height,texture.w,texture.h,texture.buf8.ptr);
    }
    void updateAtlas(FrameBuffer* fb, vec4 tilingOffset)
    {
        
    }
   
    @property uint instanceId()
	{
        return materialIndex;
	}

    static ulong materialId()
    {
        return (typeid(UniformLayout).toHash());
    }

	static void resetInstanceCount()
	{
        numMaterials = 0;
        
        
	}
    @property recieveShadows()
    {
        return shadows;
    }
    @property recieveShadows(bool shadows)
    {
        this.shadows = shadows;
    }

    static uint allocatedVertices()
	{
        return reservedVertices;
	}
    static uint allocatedElements()
	{
        return reservedElements;
	}

    SamplerObject!(TextureType.TEXTURE2D)* getTextureAtlas()
	{
        return &this.textureAtlas;
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
    static void allocate(Mesh* mesh)
	{

        reservedVertices += cast(uint)mesh.positions.length;
        reservedElements += cast(uint)mesh.faces.length;
	}
	static void allocate(uint numVertices, uint numElements)
	{

        reservedVertices += numVertices;
        reservedElements += numElements;
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


    static void useShaderProgram()
	{
        program.use();
	}



}
