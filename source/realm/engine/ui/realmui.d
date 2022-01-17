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
import realm.engine.input;
import realm.engine.ui.font;
import std.algorithm;
import realm.engine.debugdraw;
import realm.engine.container.stack;
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

	

	struct TextLayout
	{
		int charSpacing;
		int spaceWidth;
		uint fontSize;
	}

	enum ButtonState
	{
		NONE,
		HOVER,
		PRESSED,
		RELEASED
	}

	

	private static Batch!(RealmVertex) uiBatch;
	private static Batch!(RealmVertex) textBatch;
	private static StandardShaderModel uiProgram;
	private static StandardShaderModel textProgram;
	alias UIMaterialLayout = Alias!(["color" : UserDataVarTypes.VECTOR,"baseTexture" : UserDataVarTypes.TEXTURE2D]);
	alias TextMaterialLayout = Alias!(["color" : UserDataVarTypes.VECTOR,"fontTexture" : UserDataVarTypes.TEXTURE2D]);
	alias UIMaterial = Alias!(Material!(UIMaterialLayout));
	alias TextMaterial = Alias!(Material!(TextMaterialLayout,0,true));
	private static IFImage panelImage;
	private static IFImage pressedButtonImage;
	private static Camera uiCamera;
	private static Mesh panelMesh;
	private static Font font;
	private static Stack!(UIElement) containerStack;
	private static UIElement parentContainer;
	static void initialize()
	{
		
	


		panelImage = readImageBytes("$EngineAssets/Images/ui-panel.png");
		pressedButtonImage = readImageBytes("$EngineAssets/images/ui-button-pressed.png");
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
		uiCamera.projBounds = ProjectionWindowBounds.ZERO_TO_ONE;
		font = Font.load("$EngineAssets/Fonts/arial.ttf");
		parentContainer = createElement(vec3(0),vec3(1),vec3(0));

		containerStack = new Stack!(UIElement)(32);
		containerPush(parentContainer);

	}

	static UIElement createElement(vec3 position, vec3 scale, vec3 rotation)
	{

		UIMaterial material = new UIMaterial;
		material.setShaderProgram(uiProgram);
		material.textures.settings = TextureDesc(ImageFormat.RGBA8,TextureFilterfunc.LINEAR,TextureWrapFunc.CLAMP_TO_BORDER);
		material.textures.baseTexture = new Texture2D(&panelImage);
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

	private static void packStringTexture(SamplerObject!(TextureType.TEXTURE2D)* sampler, string text,TextLayout layout = TextLayout(4,8,12))
	in(sampler !is null)
	in(sampler.ID > 0)
	{

		import std.conv;
		auto chars = zip(text,text.map!(c => font.getChar(to!char(c))));
		int totalWidth = 0;
		int height = int.min;

		foreach(tup; chars)
		{
			if(tup[0] == ' ')
			{
				totalWidth += layout.spaceWidth;
			}
			totalWidth += tup[1].w + layout.charSpacing;
			if(tup[1].h > height)
			{
				height = tup[1].h ;
			}

		}
		ubyte[] space;
		space.length = layout.spaceWidth * height;
		space[0..$] = 0;		
		int currentX = 0;
		int currentY = 0;
		sampler.setActive();
		sampler.width = totalWidth;
		sampler.height = height;

		sampler.uploadImage(0,0,null);
		sampler.clear(0,[0]);
		foreach(tup; chars)
		{
			int xoffset = 0;
			int yoffset = 0;
			IFImage charTexture = tup[1];
			dchar character= tup[0];
			if(character == ' ')
			{
				charTexture.w = layout.spaceWidth;
				charTexture.h = height;
				charTexture.buf8.length = space.length;
				charTexture.buf8[0..$] = space.dup;
			}

			else if(character == '-')
			{
				yoffset = -(height/2);
			}
			int heightDiff = height - charTexture.h;
			sampler.uploadSubImage(0,currentX + xoffset,currentY + heightDiff + yoffset,charTexture.w,charTexture.h,charTexture.buf8.ptr);
			currentX += charTexture.w + layout.charSpacing;
		}
	}

	static void drawTextString(T...)(UIElement element, vec4 textColor, vec4 panelColor, TextLayout layout ,string text,T t )
	{
		import std.format : format;
		font.setPixelSize(0,layout.fontSize);
		drawPanel(element,panelColor);
		TextMaterial material;
		if(element!in TextElements.materials)
		{
			material = new TextMaterial;
			material.setShaderProgram(textProgram);
			TextElements.materials[element] = material;
		}
		TextElements.transforms[element] = UIElements.transforms[element];
		material = TextElements.materials[element];
		SamplerObject!(TextureType.TEXTURE2D)* materialAtlas = material.getTextureAtlas();
		materialAtlas.textureDesc = TextureDesc(ImageFormat.RED8,TextureFilterfunc.LINEAR,TextureWrapFunc.CLAMP_TO_BORDER);

		packStringTexture(materialAtlas,text.format(t),layout);
		material.fontTexture = vec4(1,1,0,0);
		material.color = textColor;
		UIElements.transforms[element].updateTransformation();
		RealmVertex[] vertices = panelVertices(UIElements.transforms[element],material);
		textBatch.submitVertices!(TextMaterial)(vertices,panelMesh.faces,material);
	}

	static ButtonState button(UIElement element,vec4 textColor,vec4 panelColor,string text,TextLayout layout = TextLayout(4,8,12))
	{
		import std.stdio;
		double mouseX = InputManager.getMouseAxis(MouseAxis.X);
		double mouseY = InputManager.getMouseAxis(MouseAxis.Y);
		auto windowSize = RealmApp.getWindowSize();
		mouseY = ((1 - (mouseY/cast(double)windowSize[1])) * windowSize[1]);
		UIMaterial material =UIElements.materials[element];
		material.color = panelColor;
		Transform transform = UIElements.transforms[element];

		RealmVertex[] panelVertices = panelVertices!(UIMaterial)(transform,material);
		AABB panelAABB = AABB.from_points(panelVertices.map!(v => vec3(v.position)).array);
		ButtonState result = ButtonState.NONE;
		if((mouseX >= panelAABB.min.x && mouseX <= panelAABB.max.x) && (mouseY >= panelAABB.min.y && mouseY <= panelAABB.max.y) )
		{
			if(InputManager.getMouseButton(RealmMouseButton.ButtonLeft) == KeyState.Press)
			{
				material.updateAtlas(pressedButtonImage,&material.baseTexture);
				result = ButtonState.PRESSED;
			}
			else
			{
				result = ButtonState.HOVER;
				material.updateAtlas(panelImage,&material.baseTexture);
			}
			
		}
		else
		{
			material.updateAtlas(panelImage,&material.baseTexture);
		}

		drawPanel(element,panelColor);
		drawTextString(element,textColor,panelColor,layout,text);
		
		return result;

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
		Transform parent = UIElements.transforms[containerStack.peek()];
		Transform copy = new Transform(transform);
		copy.position += parent.position;
		//copy.scale += parent.scale;
		copy.rotation += parent.rotation;
		copy.updateTransformation();
		mat4 modelMatrix = copy.transformation;
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
		

		
		
		RealmVertex[] vertices = panelVertices!(UIMaterial)(transform,material);
		material.color = color;
		
		uiBatch.submitVertices!(UIMaterial)(vertices,panelMesh.faces,material);

	}

	static void containerPush(UIElement element)
	{
		
		if(!containerStack.empty)
		{
			Transform transform = UIElements.transforms[element];
			

			transform.position += UIElements.transforms[containerStack.peek()].position;
			transform.scale += UIElements.transforms[containerStack.peek()].scale;
			transform.rotation += UIElements.transforms[containerStack.peek()].rotation;
			transform.updateTransformation();

		}
		
		containerStack.push(element);
	}
	static void containerPop()
	{
		if(containerStack.peek() == parentContainer)
		{
			Logger.LogWarning("Cant pop root container off stack");
			return;
		}
		
	
		UIElement element = containerStack.pop();
		Transform transform = UIElements.transforms[element];


		transform.position -= UIElements.transforms[containerStack.peek()].position;
		transform.scale -= UIElements.transforms[containerStack.peek()].scale;
		transform.rotation -= UIElements.transforms[containerStack.peek()].rotation;
		transform.updateTransformation();

		
		
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
