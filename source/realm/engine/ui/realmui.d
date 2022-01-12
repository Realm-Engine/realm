module realm.engine.ui.realmui;
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
import realm.engine.ui.font;
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

	protected struct TextElements
	{
		static TextMaterial[UUID] materials;
		static Transform[UUID] transforms;
	}

	private static Batch!(RealmVertex) uiBatch;
	private static Batch!(RealmVertex) textBatch;
	private static ShaderProgram uiProgram;
	private static ShaderProgram textProgram;
	alias UIMaterialLayout = Alias!(["color" : UserDataVarTypes.VECTOR,"baseTexture" : UserDataVarTypes.TEXTURE2D]);
	alias TextMaterialLayout = Alias!(["color" : UserDataVarTypes.VECTOR,"fontTexture" : UserDataVarTypes.TEXTURE2D]);
	alias UIMaterial = Alias!(Material!(UIMaterialLayout));
	alias TextMaterial = Alias!(Material!(TextMaterialLayout));
	private static IFImage panelImage;
	private static Camera uiCamera;
	private static Mesh panelMesh;
	private static Font font;
	
	static void initialize()
	{
		
		FTSupport ret = loadFreeType();

		Logger.LogError(ret != FTSupport.noLibrary,"Could not find freetype library");
		Logger.LogError(ret != FTSupport.badLibrary,"Failed to load freetype");
		Logger.LogInfo(ret != FTSupport.badLibrary && ret != FTSupport.noLibrary,"Loaded freetype version %s", ret);

		panelImage = readImageBytes("$EngineAssets/Images/ui-panel.png");
		panelMesh = loadMesh("$EngineAssets/Models/ui-panel.obj");
		panelMesh.calculateTangents();
		uiProgram = loadShaderProgram("$EngineAssets/Shaders/ui.shader","UI");
		textProgram = loadShaderProgram("$EngineAssets/Shaders/text.shader","Text");
		UIMaterial.initialze();
		UIMaterial.reserve(16);
		UIMaterial.allocate(512,512);
		uiBatch = new Batch!(RealmVertex)(MeshTopology.TRIANGLE,uiProgram,11);
		uiBatch.setShaderStorageCallback(&(UIMaterial.bindShaderStorage));
		uiBatch.initialize(UIMaterial.allocatedVertices(),UIMaterial.allocatedElements());
		uiBatch.reserve(16);
		TextMaterial.initialze();
		TextMaterial.reserve(16);
		TextMaterial.allocate(512,512);
		textBatch = new Batch!(RealmVertex)(MeshTopology.TRIANGLE,textProgram,11);
		textBatch.setShaderStorageCallback(&(TextMaterial.bindShaderStorage));
		textBatch.initialize(TextMaterial.allocatedVertices(),TextMaterial.allocatedElements());
		textBatch.reserve(16);
		
		Tuple!(int,int) windowSize = RealmApp.getWindowSize();
		uiCamera = new Camera(CameraProjection.ORTHOGRAPHIC,vec2(windowSize[0],windowSize[1]),-1,100,0);
		font = Font.load("$EngineAssets/Fonts/arial.ttf");


	}

	static UIElement createElement(vec3 position, vec3 scale, vec3 rotation)
	{

		UIMaterial material = new UIMaterial;
		material.setShaderProgram(uiProgram);
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

	static void drawCharacter(UIElement element, vec4 textColor,vec4 panelColor, char character,uint fontSize = 48)
	{
		font.setPixelSize(0,fontSize);
		IFImage fontChar = font.getChar(character);
		drawPanel(element,panelColor);
		if(fontChar.w <= 0 || fontChar.h <= 0)
		{
			return;
		}
		TextMaterial material;
		if( element !in TextElements.materials)
		{
			material = new TextMaterial;
			material.setShaderProgram(textProgram);
			TextElements.materials[element] = material;
			material.textures.settings = TextureDesc(ImageFormat.RED,TextureFilterfunc.LINEAR,TextureWrapFunc.CLAMP_TO_BORDER);
			material.textures.fontTexture = new Texture2D(&fontChar,material.textures.settings);
			material.packTextureAtlas();

		}
		else
		{
			material = TextElements.materials[element];
			material.updateAtlas(fontChar,&material.fontTexture);

		}
		TextElements.transforms[element] = UIElements.transforms[element];
	
		
		material.color = textColor;
		Transform transform = UIElements.transforms[element];
		transform.updateTransformation();
		RealmVertex[] vertices = panelVertices(transform,material);
		
		textBatch.submitVertices!(TextMaterial)(vertices,panelMesh.faces,material);
		
	}

	static private RealmVertex[] panelVertices(Mat)(Transform transform,Mat material)
	in
	{
		static assert(isMaterial!(Mat));
	}
	do
	{
		RealmVertex[] vertices;
		vertices.length = panelMesh.positions.length;
		mat4 modelMatrix = transform.transformation;
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
		return vertices;
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
		GraphicsSubsystem.disableDepthTest();
		uiCamera.update();
		mat4 vp = uiCamera.projection;
		vp.transpose();
		Renderer.get.globalData.vp[0..$] = vp.value_ptr[0..16].dup;
		GraphicsSubsystem.updateGlobalData(Renderer.get.globalData);
		uiBatch.drawBatch!(false,PrimitiveShape.TRIANGLE);
		textBatch.drawBatch!(false,PrimitiveShape.TRIANGLE);
		uiBatch.resetBatch();
		textBatch.resetBatch();
		GraphicsSubsystem.enableDepthTest();
	}

	





}
