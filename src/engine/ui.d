module realm.engine.ui;
import realm.engine.graphics.batch;
import realm.engine.graphics.graphicssubsystem;
import realm.engine.graphics.core;
import realm.engine.core;
import realm.engine.app;
import realm.engine.asset;
import realm.engine.graphics.material;
import std.range;
import std.uuid;
import bindbc.freetype;
static class RealmUI
{

	struct UIElement
	{
		UUID id;
		alias id this; 
	}

	protected struct UIElements
	{
		static UIMaterial[UUID] materials;
		static Transform[UUID] transforms;
	}

	private static Batch!(RealmVertex) uiBatch;
	private static ShaderProgram uiProgram;
	alias UIMaterialLayout = Alias!(["color" : UserDataVarTypes.VECTOR,"baseTexture" : UserDataVarTypes.TEXTURE2D]);
	alias UIMaterial = Alias!(Material!(UIMaterialLayout));
	private static IFImage panelImage;
	private static Camera uiCamera;
	private static Mesh panelMesh;
	private static UIMaterial[] materials;
	
	static void initialize()
	{
		
		FTSupport ret = loadFreeType();
		
		Logger.LogError(ret != FTSupport.noLibrary,"Could not find freetype library");
		Logger.LogError(ret != FTSupport.badLibrary,"Failed to load freetype");
		

		panelImage = readImageBytes("./src/engine/Assets/Images/ui-panel.png");
		panelMesh = loadMesh("./src/engine/Assets/Models/ui-panel.obj");
		panelMesh.calculateTangents();
		uiProgram = loadShaderProgram("./src/engine/Assets/Shaders/ui.shader","UI");
		UIMaterial.initialze();
		UIMaterial.reserve(16);
		UIMaterial.allocate(512,512);
		uiBatch = new Batch!(RealmVertex)(MeshTopology.TRIANGLE,uiProgram,11);
		uiBatch.setShaderStorageCallback(&(UIMaterial.bindShaderStorage));
		uiBatch.initialize(UIMaterial.allocatedVertices(),UIMaterial.allocatedElements());
		uiBatch.reserve(16);
		
		Tuple!(int,int) windowSize = RealmApp.getWindowSize();
		uiCamera = new Camera(CameraProjection.ORTHOGRAPHIC,vec2(windowSize[0],windowSize[1]),-1,100,0);

	}


	static UIElement createElement(vec3 position, vec3 scale, vec3 rotation)
	{

		UIMaterial material = new UIMaterial;
		material.textures.settings = TextureDesc(ImageFormat.RGBA8,TextureFilterfunc.LINEAR,TextureWrapFunc.CLAMP_TO_BORDER);
		material.textures.baseTexture = new Texture2D(&panelImage,material.textures.settings);
		material.color = vec4(1,1,1,1);
		material.packTextureAtlas();
		Transform transform = new Transform(position ,rotation,scale);		
		UIElement element = {randomUUID()};
		UIElements.transforms[element] = transform;
		UIElements.materials[element] = material;
		return element;

	}

	static void drawPanel(UIElement element,vec4 color)
	{
		drawPanel(UIElements.materials[element],UIElements.transforms[element],color);
	}

	static void drawPanel(UIMaterial material, Transform transform,vec4 color)
	{
		
		transform.updateTransformation();
		mat4 modelMatrix = transform.transformation;

		RealmVertex[] vertices;
		vertices.length = panelMesh.positions.length;
		material.color = color;
		for(int i = 0; i < panelMesh.positions.length;i++)
		{
			RealmVertex vertex;
			vertex.position = vec3( modelMatrix * vec4(panelMesh.positions[i],1.0));
			vertex.texCoord = panelMesh.textureCoordinates[i];
			vertex.normal =  vec3(modelMatrix * vec4(0,0,1,1));
			vertex.tangent = vec3(modelMatrix * vec4(panelMesh.tangents[i],1.0));
			vertex.materialId = material.instanceId;
			
			vertices[i] = vertex;

		}
		uiBatch.submitVertices!(UIMaterial)(vertices,panelMesh.faces,material);

	}

	static void flush()
	{
		import realm.engine.graphics.renderer : Renderer;
		uiCamera.update();
		mat4 vp = uiCamera.projection;
		vp.transpose();
		Renderer.get.globalData.vp[0..$] = vp.value_ptr[0..16].dup;
		GraphicsSubsystem.updateGlobalData(Renderer.get.globalData);
		uiBatch.drawBatch!(false,PrimitiveShape.TRIANGLE);
		uiBatch.resetBatch();
	}

	





}
