module realmofthedead.gameentity;
import realm.engine.core;
import realm.engine.graphics.core;
import realm.engine.graphics.material;
import realm.engine.graphics.renderer;
import realm.engine.debugdraw;
import realm.engine.physics.collision;
import std.stdio;
alias SimpleMaterial = Alias!(Material!(["color" : UserDataVarTypes.VECTOR,
										 "diffuse" : UserDataVarTypes.TEXTURE2D,
										 "normal" : UserDataVarTypes.TEXTURE2D,
										 "specularPower" : UserDataVarTypes.FLOAT,
										 "shinyness" : UserDataVarTypes.FLOAT],2));
static StandardShaderModel entityShader;

 


mixin template GameEntity(string name ,T...)
{
	
	mixin RealmEntity!(name, T);
	private SimpleMaterial material;

	static StandardShaderModel getEntityShader()
	{
		if(entityShader is null)
		{
			entityShader = loadShaderProgram("$EngineAssets/Shaders/simpleShaded.shader","Simple shader");
		}
		return entityShader;
	}

}
//
//class GameEntity
//{
//
//    mixin RealmEntity!("GameEntity",Transform,Mesh,SimpleCollider);
//    
//    private static StandardShaderModel shader;
//    private static IFImage diffuse;
//    private Transform transform;
//    private Mesh* mesh;
//    
//
//
//    void start(string modelPath)
//    {
//        
//        start(loadMesh(modelPath));
//
//    }
//
//
//
//    void start(Mesh mesh)
//    {
//        
//        transform = getComponent!(Transform);
//        material = new SimpleMaterial;
//        if(shader is null)
//        {
//            shader = loadShaderProgram("$EngineAssets/Shaders/simpleShaded.shader","Simple shaded");
//        }
//        setComponent!(Mesh)(mesh);
//        this.mesh = &(getComponent!(Mesh)());
//        SimpleMaterial.allocate(this.mesh);
//        material.textures.settings = TextureDesc(ImageFormat.RGBA8,TextureFilterfunc.LINEAR,TextureWrapFunc.CLAMP_TO_BORDER);
//        material.specularPower = 1.0;
//        material.shinyness = 32;
//        material.setShaderProgram(shader);
//        material.textures.diffuse = Vector!(int,4)(255,255,255,255);
//        material.textures.normal = Vector!(int,4)(0,1,0,0);
//        material.color = vec4(1,1,1,1);
//        material.packTextureAtlas();
//        
//        
//    }
//
//
//    static this()
//    {
//        
//        
//    }
//    @property color(vec4 color)
//    {
//        material.color = color;
//    }
//
//    void update()
//    {
//        updateComponents();
//        draw(Renderer.get);
//
//
//    }
//
//    SimpleMaterial* getMaterial()
//    {
//        return &material;
//    }
//
//
//    void draw(Renderer renderer)
//    {
//        if(active)
//        {
//            renderer.submitMesh!(SimpleMaterial,false)(*mesh,transform,material);
//        }
//
//
//    }
//    void debugDraw()
//    {
//
//        
//    }
//
//
//}