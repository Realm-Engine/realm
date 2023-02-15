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
import realm.engine.memory.core;


struct MaterialData
{
    ubyte[] dataBlock;
    TypeInfo layoutTypeInfo;
    StandardShaderModel shader;
    //uint[string] textures;
    uint* textureLocations;
    uint* textures;
    Sampler* samplers;
    size_t numTextures;
    
}

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
                pragma(msg, "Uniform: " ~ uniform);
                //string type;
                static if (uniforms[uniform] == UserDataVarTypes.FLOAT)
                {
                    mixin("%s %s;".format("float", uniform));
                    mixin("%s %s;".format("float",(uniform~"packing")));
                }

                static if (uniforms[uniform] == UserDataVarTypes.VECTOR)
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
                    mixin("@(\"Sampler\") %s %s_Sampler;".format("Sampler", uniform));
                }

            }
        }

    }
    
    struct MaterialTexture
    {
        private const int TEXTURE_COLOR_SIZE = 32;
        enum InternalType
    	{
            TEXTURE,
            COLOR
    	}
        private InternalType type;
        union
    	{
            
    		Texture2D texture;
    		Vector!(ubyte,4) color;
    	}
    
    	void opAssign(Texture2D texture)
    	{
    		this.texture = texture;
            type = InternalType.TEXTURE;
    	}
    	void opAssign(Vector!(ubyte,4) c)
    	{
    		color = c;
            type = InternalType.COLOR;
    	}
    
        void opAssign(Vector!(int,4) c)
    	{
            color.r = cast(ubyte)c.r;
            color.g = cast(ubyte)c.g;
            color.b = cast(ubyte)c.b;
            color.a = cast(ubyte)c.a;
            type = InternalType.COLOR;
    	}
        void opAssign(MaterialTexture other)
		{
            type = other.type;
		    if(other.type == InternalType.TEXTURE)
			{
			    texture = other.texture;
                
			}
            else
			{
			    color.r = cast(ubyte)other.color.r;
				color.g = cast(ubyte)other.color.g;
				color.b = cast(ubyte)other.color.b;
				color.a = cast(ubyte)other.color.a;
				
			}
		}
    
        
        @property bool isTexture() 
    	{
    		return type == InternalType.TEXTURE;
    	}
        @property bool isColor()
    	{
            return type == InternalType.COLOR;
    	}
    
        
    
        Vector!(ubyte,4) opCast(T : Vector!(ubyte,4))() 
        in(isColor)
    	{
            return color;
    	}
        Texture2D opCast(T:Texture2D)() 
        in(isTexture)
    	{
            return texture;
    	}
        
    
        int width()
    	{
            if(type == InternalType.TEXTURE)
    		{
                return texture.w;
    		}
            else
    		{
                return TEXTURE_COLOR_SIZE;
    		}
    	}
       int height()
    	{
            if(type == InternalType.TEXTURE)
    		{
                return texture.h;
    		}
            else
    		{
                return TEXTURE_COLOR_SIZE;
    		}
    	}
    }

}



enum bool isMaterial(T) = (__traits(hasMember, T, "shaderStorageBuffer") == true && __traits(hasMember, T, "textures") == true && __traits(hasMember, T, "layout") == true);
enum texturesMembers(T) = (__traits(allMembers, T.Textures));
enum texturesAttributes(T, alias Member) = (__traits(getAttributes, __traits(getMember, T.Textures, Member)));
enum isTexture(alias T) = (T == "Texture");
class Material(UserDataVarTypes[string] uniforms = [],int order = 1, bool overrideTexturePacking = false)
{
    import std.format;
    import std.stdio;

    mixin MaterialLayout!(uniforms);
    UniformLayout.Textures textures;
    UniformLayout.UserData layout;
    alias layout this;
    private static uint numMaterials = 0;
    private uint materialIndex = 0;    
    public StandardShaderModel program;
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
        
        
        
        materialIndex = numMaterials;
        numMaterials++; 
        shadows = true;


		
    }

    ~this()
	{
		
       
		numMaterials--;
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

    public MaterialData data()
	{
        MaterialData data;
        data.dataBlock = (cast(ubyte*)&layout)[0..UniformLayout.UserData.sizeof].dup;
        data.layoutTypeInfo = typeid( UniformLayout.UserData);
        data.shader = program;
        data.textureLocations = (cast(uint *) MemoryUtil.allocateChunk(0));
        data.textures = (cast(uint *) MemoryUtil.allocateChunk(0));
        data.samplers = (cast(Sampler *)MemoryUtil.allocateChunk(0));
        size_t numTextures = 0;
		static foreach (member; texturesMembers!(UniformLayout))
        {
            static foreach (attribute; texturesAttributes!(UniformLayout, member))
            {
                static if (isTexture!(attribute))
                {
                    {
                        Texture2D texture= __traits(getMember,textures,member);
                        if(texture!is null)
						{
                            uint id = texture.textureObject;
                            uint location = program.uniformLocation(member);
                            numTextures++;
                            data.textureLocations = cast(uint *) MemoryUtil.resizeChunk(cast(void*)data.textureLocations,numTextures * uint.sizeof);
                            data.textures = cast(uint *) MemoryUtil.resizeChunk(cast(void*)data.textures,numTextures * uint.sizeof);
                            data.samplers = cast(Sampler *) MemoryUtil.resizeChunk(cast(void*)data.samplers,numTextures * Sampler.sizeof);
                            data.textureLocations[numTextures - 1] = location;
							data.textures[numTextures - 1]  = texture.textureObject;
							data.samplers[numTextures - 1] = __traits(getMember,textures,member~"_Sampler");
						}
                        
					}
                    
				}
			}
		}
        data.numTextures = numTextures;
        

        return data;
	}
}

alias BlinnPhongMaterial = Alias!(Material!(["ambient" : UserDataVarTypes.VECTOR,
											 "diffuse" : UserDataVarTypes.TEXTURE2D,
											 "normal" : UserDataVarTypes.TEXTURE2D,
											 "specular" : UserDataVarTypes.TEXTURE2D,
											 "shininess" : UserDataVarTypes.FLOAT,
											 "padding" : UserDataVarTypes.FLOAT]));
alias ToonMaterial = Alias!(Material!(["baseColor" : UserDataVarTypes.VECTOR,
                                        "diffuse" : UserDataVarTypes.TEXTURE2D
                                        ]));
//alias ToonMaterialInstance = Instantiate(Material,["baseColor":UserDa])

   /*    
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
        Tuple!(MaterialTexture*,vec4*)[] textures;
		int sumWidth = 0;
        int sumHeight = 0;

        static foreach (member; texturesMembers!(UniformLayout))
        {
            static foreach (attribute; texturesAttributes!(UniformLayout, member))
            {
                static if (isTexture!(attribute))
                {
                    
                    

                    if(&__traits(getMember, this.textures, member) !is null)
					{
                       
						
						textures~= tuple(&__traits(getMember, this.textures, member),&__traits(getMember,this.layout,member));
						sumWidth += __traits(getMember, this.textures, member).width();
						sumHeight += __traits(getMember, this.textures, member).height();
						
                       

					}

                    

				}
			}
		}
        auto sortedTextures = textures.sort!((t1, t2) => (t1[0].width() * t1[0].height()) > (t2[0].width() * t2[0].height()));
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
        int textureAtlasWidth = sumWidth;
        int textureAtlasHeight = sumHeight;
        if(sortedTextures.length > 1)
		{
			textureAtlasWidth = nextMultiple(sumWidth,256);
			textureAtlasHeight = nextMultiple(sumHeight,256);
		}


      
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
       
        
        foreach(index,materialTexture; sortedTextures.enumerate(0))
		{
WriteImage:
            int width = materialTexture[0].width();
            int height = materialTexture[0].height();
            
            if(width + rowWidth <= cast(int)textureAtlas.width)
			{
                
                materialTexture[1].x = cast(float)width / textureAtlas.width;
                materialTexture[1].y = cast(float)height/ textureAtlas.height;
                materialTexture[1].z = cast(float)rowWidth / textureAtlas.width;
                materialTexture[1].w = cast(float)totalHeight/textureAtlas.height;
                if(materialTexture[0].isTexture)
				{
                    Texture2D tex = cast(Texture2D) *materialTexture[0];
                    
                    textureAtlas.uploadSubImage(0,rowWidth,totalHeight,width,height,tex.buf8.ptr);
                    
				}
                else
				{
					Vector!(ubyte,4) color = cast(Vector!(ubyte,4)) *materialTexture[0];
                    textureAtlas.clear(0,rowWidth,totalHeight,width,height,color.vector.dup);
				}
                

				if(cast(int)materialTexture[0].height() > rowHeight)
				{
                    rowHeight = height;
				}
                rowWidth += width;


			}
            else
            {
                totalHeight += rowHeight;
                rowWidth = 0;
                goto WriteImage;
			}


		}
       // GraphicsSubsystem.endPixelTransfer(pbo);

       
	}

    void clearTexture(vec4 tilingOffset, vec4 color)
	{
        int x = cast(int)(tilingOffset.z * textureAtlas.width);
        int y = cast(int)(tilingOffset.w * textureAtlas.height);
        int w =cast(int)( tilingOffset.x * textureAtlas.width);
        int h = cast(int)(tilingOffset.y * textureAtlas.height);
        textureAtlas.clear(0,x,y,w,h,cast(real[])color.vector.dup);
	}

    void updateAtlas(IFImage image, vec4* tilingOffset)
	{
        vec4 clearColor = vec4(0);
        tilingOffset.x = cast(float)image.w / textureAtlas.width;
        tilingOffset.y = cast(float)image.h / textureAtlas.height;
		int x = cast(int)(tilingOffset.z * textureAtlas.width);
        int y = cast(int)(tilingOffset.w * textureAtlas.height);
        int w = image.w;
        int h = image.h;
        textureAtlas.clear!(float)(0,x,y,w,h,clearColor.vector.dup);
        textureAtlas.uploadSubImage(0,x,y,w,h,image.buf8.ptr);
	}

    void updateAtlas(Texture2D texture, vec4 tilingOffset)
    {
		tilingOffset.x = cast(float)texture.w / textureAtlas.width;
        tilingOffset.y = cast(float)texture.h / textureAtlas.height;
        vec4 clearColor = vec4(0);
        int x = cast(int)(tilingOffset.z * textureAtlas.width);
        int y = cast(int)(tilingOffset.w * textureAtlas.height);
        int w = texture.w;
        int h = texture.h;
        textureAtlas.clear!(float)(0,x,y,w,h,clearColor.vector);
        textureAtlas.uploadSubImage(0,x,y,w,h,texture.buf8.ptr);
    }
    void updateAtlas(FrameBuffer* fb, vec4 tilingOffset)
    {
        
    }*/