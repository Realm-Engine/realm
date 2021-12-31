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

                static if (uniforms[uniform] == UserDataVarTypes.VECTOR || uniforms[uniform] == UserDataVarTypes.TEXTURE2D || uniforms[uniform] == UserDataVarTypes.FRAMEBUFFER)
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

                    mixin("@(\"Texture\") %s %s;".format("Texture2D", uniform));
                }
                static if(uniforms[uniform] == UserDataVarTypes.FRAMEBUFFER)
                {
                    mixin("@(\"FrameBuffer\") %s %s;".format("FrameBuffer*", uniform));
                }
            }
        }

    }

}


enum bool isMaterial(T) = (__traits(hasMember, T, "shaderStorageBuffer") == true && __traits(hasMember, T, "textures") == true && __traits(hasMember, T, "layout") == true);
enum texturesMembers(T) = (__traits(allMembers, T.Textures));
enum texturesAttributes(T, alias Member) = (__traits(getAttributes, __traits(getMember, T.Textures, Member)));
enum isTexture(alias T) = (T == "Texture");
enum isFrameBuffer(alias T) = (T == "FrameBuffer");
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
        //writeln(numMaterials);
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
        FrameBuffer*[] frameBuffers;
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
                static if(isFrameBuffer!(attribute))
                {
                    if(__traits(getMember,this.textures,member) !is null)
                    {
                        frameBuffers ~= __traits(getMember,this.textures,member);
                        tilingOffsets ~= &__traits(getMember,this.layout,member);
                        sumWidth +=   __traits(getMember, this.textures, member).width;
                        sumHeight += __traits(getMember, this.textures, member).height;

                    }
                }
			}
		}
        
        int textureAtlasWidth = cast(int)(sumWidth * 1.5);
        int textureAtlasHeight = cast(int)(sumHeight * 1.5);
        Logger.LogInfo("Createing atlas texture size (%d,%d)",textureAtlasWidth,textureAtlasHeight);
        auto sortedTextures = textures.sort!((t1, t2) => (t1.w * t1.h) > (t2.w * t2.h));
        auto sortedFrameBuffers = frameBuffers.sort!((s1, s2) => (s1.width * s1.height) > (s2.width * s2.height));
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
            if(texture.w + rowWidth < cast(int)textureAtlas.width)
			{
                
                 vec4 tilingOffset = calculateTilingOffset(texture.w,texture.h);
                *tilingOffsets[index] = tilingOffset;
                //textureAtlas.uploadSubImage(0,rowWidth,totalHeight,texture.w,texture.h,texture.buf8.ptr);
                updateAtlas(texture,*tilingOffsets[index]);

               
                
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

        foreach(index, framebuffer ; sortedFrameBuffers.enumerate(0))
        {
WriteFrameBuffer:
            if(framebuffer.width + rowWidth < cast(int) textureAtlas.width)
            {
                framebuffer.copyToTexture2D(textureAtlas,0,rowWidth,totalHeight,framebuffer.width,framebuffer.height);
                *tilingOffsets[index] = calculateTilingOffset(framebuffer.width, framebuffer.height);
                if(cast(int)framebuffer.width > rowWidth)
                {
                    rowHeight = framebuffer.height;
                }
                rowWidth += framebuffer.width;
            }
            else
            {
                totalHeight += rowHeight;
                rowWidth = 0;
                goto WriteFrameBuffer;
            }
            
            
        }
       
	}

    void updateAtlas(Texture2D texture, vec4 tilingOffset)
    {
        textureAtlas.uploadSubImage(0,cast(int)tilingOffset.z * textureAtlas.width,cast(int)tilingOffset.w * textureAtlas.height,texture.w,texture.h,texture.buf8.ptr);
    }
    void updateAtlas(FrameBuffer* fb, vec4 tilingOffset)
    {
        fb.copyToTexture2D(textureAtlas,0,cast(int)tilingOffset.z * textureAtlas.width,cast(int)tilingOffset.w * textureAtlas.height,fb.width,fb.height);
    }
   

    static ulong materialId()
    {
        return (typeid(UniformLayout).toHash());
    }

}
