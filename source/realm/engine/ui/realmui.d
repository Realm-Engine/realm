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
import std.string;
static class RealmUI
{
	enum bool isValidUIMaterial(T) = (isMaterial!(T));

	

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
		static string[UUID] strings;
	}

	struct UITheme
	{
		vec4 panelColor;
		vec4 textColor;
		

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
	private static Stack!(UITheme) themeStack;
	private static UIElement parentContainer;
	private static InputEvent _currentEvent;
	private static UIElement focusedElement;


	static void initialize()
	{
		panelImage = readImageBytes("$EngineAssets/Images/ui-panel.png");
		pressedButtonImage = readImageBytes("$EngineAssets/images/ui-button-pressed.png");
		panelMesh = loadMesh("$EngineAssets/Models/ui-panel.obj");
		panelMesh.calculateTangents();
		uiProgram = loadShaderProgram("$EngineAssets/Shaders/ui.shader","UI");
		textProgram = loadShaderProgram("$EngineAssets/Shaders/text.shader","Text");
		UIMaterial.initialze();
		UIMaterial.reserve(32);
		UIMaterial.allocate(512,512);
		uiBatch = new Batch!(RealmVertex)(MeshTopology.TRIANGLE,uiProgram,11);
		uiBatch.setShaderStorageCallback(&(UIMaterial.bindShaderStorage));
		uiBatch.initialize(UIMaterial.allocatedVertices(),UIMaterial.allocatedElements());
		uiBatch.reserve(32);
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
		themeStack = new Stack!(UITheme)(8);
		containerPush(parentContainer);
		themePush(UITheme(vec4(1),vec4(1)));
		InputManager.registerInputEventCallback(&inputEvent);

	}

	static void inputEvent(InputEvent event)
	{
		_currentEvent = event;
	}

	static UIElement createElement(vec3 position, vec3 scale, vec3 rotation)
	{

		UIMaterial material = new UIMaterial;
		material.setShaderProgram(uiProgram);
		material.textures.settings = TextureDesc(ImageFormat.SRGBA8,TextureFilterfunc.LINEAR,TextureWrapFunc.CLAMP_TO_BORDER);
		material.textures.baseTexture = new Texture2D(&panelImage);
		material.color = vec4(1,1,1,1);
		material.packTextureAtlas();
		Transform transform = new Transform(position ,rotation,scale);		
		UIElement element = {randomUUID()};
		UIElements.transforms[element] = transform;
		UIElements.materials[element] = material;
		return element;

	}

	static UIElement createElement(vec3 position, vec3 scale, vec3 rotation,Texture2D texture,TextureDesc desc)
	{

		UIMaterial material = new UIMaterial;
		material.setShaderProgram(uiProgram);
		material.textures.settings = desc;
		material.textures.baseTexture = texture;
		material.color = vec4(1,1,1,1);
		material.packTextureAtlas();
		Transform transform = new Transform(position ,rotation,scale);		
		UIElement element = {randomUUID()};
		UIElements.transforms[element] = transform;
		UIElements.materials[element] = material;
		return element;

	}

	static void deleteElement(UIElement element)
	{
		if(auto material = element in UIElements.materials)
		{
			UIElements.materials.remove(element);
			UIElements.transforms.remove(element);
			material.destroy();
		}
		if(auto material = element in TextElements.materials)
		{
			TextElements.materials.remove(element);
			TextElements.transforms.remove(element);
			material.destroy();
		}
	}

	static void drawPanel(UIElement element)
	{
		drawPanel(UIElements.materials[element],UIElements.transforms[element]);
	}

	private static void packStringTexture(SamplerObject!(TextureType.TEXTURE2D)* sampler, string text,TextLayout layout = TextLayout(4,8,12))
	in(sampler !is null)
	in(sampler.ID > 0)
	{

		import std.conv;
		auto chars = zip(text,text.map!(c => font.getChar(to!char(c)))).take(text.length);
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

	static void drawTextString(T...)(UIElement element,TextLayout layout ,string text,T t )
	{
		import std.algorithm.comparison;
		import std.format : format;
		font.setPixelSize(0,layout.fontSize);
		drawPanel(element);
		TextMaterial material;
		
		if(element!in TextElements.materials)
		{
			material = new TextMaterial;
			material.setShaderProgram(textProgram);
			TextElements.strings[element] = "";
			TextElements.materials[element] = material;
		}
		TextElements.transforms[element] = UIElements.transforms[element];
		Transform transform = TextElements.transforms[element];
		material = TextElements.materials[element];
		SamplerObject!(TextureType.TEXTURE2D)* materialAtlas = material.getTextureAtlas();
		materialAtlas.textureDesc = TextureDesc(ImageFormat.RED8,TextureFilterfunc.LINEAR,TextureWrapFunc.CLAMP_TO_BORDER);
		string formatted = text.format(t);
		int numCharsFit =cast(int)( transform.scale.x / cast(float) layout.fontSize);
		string justified = rightJustify(formatted,numCharsFit);
		TextElements.strings.update(element,
									{
										
										packStringTexture(materialAtlas,justified[0..numCharsFit],layout);
										return formatted;
									},
									(string s)
									 {
										if(cmp(formatted,s) != 0)
										{
											packStringTexture(materialAtlas,justified[0..numCharsFit],layout);
										}
										return formatted;
									 });
		material.fontTexture = vec4(1,1,0,0);
		applyTheme!(TextMaterial)(material);
		UIElements.transforms[element].updateTransformation();
		RealmVertex[] vertices = panelVertices(UIElements.transforms[element],material);
		textBatch.submitVertices!(TextMaterial)(vertices,panelMesh.faces,material);
	}

	static bool mouseOverElement(UIElement element, RealmVertex[] vertices)
	{
		double mouseX = InputManager.getMouseAxis(MouseAxis.X);
		double mouseY = InputManager.getMouseAxis(MouseAxis.Y);
		auto windowSize = RealmApp.getWindowSize();
		mouseY = ((1 - (mouseY/cast(double)windowSize[1])) * windowSize[1]);
		AABB panelAABB = AABB.from_points(vertices.map!(v => vec3(v.position)).array);
		return (mouseX >= panelAABB.min.x && mouseX <= panelAABB.max.x) && (mouseY >= panelAABB.min.y && mouseY <= panelAABB.max.y);
	}

	static ButtonState button(UIElement element,string text,TextLayout layout = TextLayout(4,8,12))
	{
		import std.stdio;
		
		Transform transform = UIElements.transforms[element];
		UIMaterial material = UIElements.materials[element];

		RealmVertex[] panelVertices = panelVertices!(UIMaterial)(transform,material);
		
		ButtonState result = ButtonState.NONE;
		if(mouseOverElement(element,panelVertices) && _currentEvent.action == InputActionType.MouseAction)
		{
			if(_currentEvent.mouseEvent.state == KeyState.Press)
			{
				material.updateAtlas(pressedButtonImage,&material.baseTexture);
				result = ButtonState.PRESSED;
			}
			else if(_currentEvent.mouseEvent.state == KeyState.Release)
			{
				material.updateAtlas(panelImage,&material.baseTexture);
				result = ButtonState.RELEASED;
			}
			else
			{
				result = ButtonState.HOVER;
				//material.updateAtlas(panelImage,&material.baseTexture);
			}
			
		}
		else
		{
			material.updateAtlas(panelImage,&material.baseTexture);
		}

		drawPanel(element);
		drawTextString(element,layout,text);
		
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

	private static void applyTheme(Mat)(Mat material)
	in
	{
		static assert(isValidUIMaterial!(Mat));

	}
	do
	{
		UITheme theme = themeStack.peek();
		static if(is(Mat == UIMaterial))
		{
			
			material.color = theme.panelColor;
		}
		static if(is(Mat == TextMaterial))
		{
			
			material.color = theme.textColor;
		}
	}

	static void drawPanel(UIMaterial material, Transform transform)
	{
		

		
		
		RealmVertex[] vertices = panelVertices!(UIMaterial)(transform,material);
		applyTheme!(UIMaterial)(material);
		
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

	static void textBox(UIElement element, TextLayout layout)
	{
		
		Transform transform = UIElements.transforms[element];
		UIMaterial material = UIElements.materials[element];
		RealmVertex[] panelVertices = panelVertices!(UIMaterial)(transform,material);
		if(mouseOverElement(element,panelVertices) && _currentEvent.action == InputActionType.MouseAction)
		{
			if(_currentEvent.mouseEvent.state == KeyState.Release)
			{
				focusedElement = element;
			}
			
		}
		TextMaterial textMaterial;
		if(element !in TextElements.materials)
		{
			textMaterial = new TextMaterial;
			textMaterial.setShaderProgram(textProgram);
			TextElements.strings[element] = "";
			TextElements.materials[element] = textMaterial;
		}
		TextElements.transforms[element] = UIElements.transforms[element];
		string text = TextElements.strings[element];
		int numCharsFit = cast(int)(transform.scale.x / cast(float)layout.fontSize);
		if(focusedElement == element)
		{
			
			
			if(_currentEvent.action == InputActionType.KeyAction)
			{
				if(_currentEvent.keyEvent.state == KeyState.Press)
				{
					if(_currentEvent.keyEvent.character != '\0')
					{
						text ~= _currentEvent.keyEvent.character;
					}
					
				}
				
			}
		}
		
		
		//Logger.LogInfo("%s", TextElements.strings[element]);
		drawTextString(element,layout,text);
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

	static void themePush(UITheme theme)
	{
		if(themeStack.length > themeStack.capacity)
		{
			Logger.LogWarning("Only %d themes can be on stack", themeStack.capacity);
			return;
		}
		themeStack.push(theme);
	}
	static UITheme themePop()
	{
		return themeStack.pop();
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
		_currentEvent.action = InputActionType.None;
		
	}
}
