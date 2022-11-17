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
import std.algorithm : map;
import realm.engine.debugdraw;
import realm.engine.container.stack;
import core.memory : GC;
import std.string;
import std.stdio;
private 
{
	import realm.engine.memory : RealmArenaAllocator;
}
static class RealmUI
{
	enum bool isValidUIMaterial(T) = (isMaterial!(T));

	

	struct UIElement
	{
		UUID id;
		alias id this;
		void opAssign(string s)
		{
			TextElements.strings.update(id,
										{
											TextElements.materials[id] = new TextMaterial;
											return s;
										},
										(string old)
										{
											return s;
										});
		}
		
		@property textLayout(TextLayout layout)
		{
			TextElements.layouts[id] = layout;
		}

		ref Mat getMaterial(Mat)()
		{
			static if(is(Mat == UIMaterial))
			{

				return UIElements.materials[id];
			}
			static if(is(Mat == TextMaterial))
			{

				return TextElements.materials[id];
			}
		}


	}

	mixin template UIElementType(Mat)
	{
		static assert(isMaterial!(Mat));
		static Mat[UUID] materials;
		static Transform[UUID] transforms;


	}

	protected struct UIElements
	{
		mixin UIElementType!(UIMaterial);
	}

	protected struct TextElements
	{
		mixin UIElementType!(TextMaterial);
		static string[UUID] strings;
		static TextLayout[UUID] layouts;
	}

	protected struct DropdownElements
	{
		mixin UIElementType!(TextMaterial);
		static bool[UUID] showOptions;
		static UIElement[][UUID] shownOptions;

	}

	protected struct SliderElements
	{
		static UIElement[UUID] sliders;
		static bool[UUID] sliderHeld;
		static Vector!(double,2) lastMousePosition;
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
	private static IFImage sliderImage;
	private static Camera uiCamera;
	private static Mesh panelMesh;
	private static Font font;
	private static Stack!(UIElement,0) containerStack;
	private static Stack!(UITheme) themeStack;
	private static UIElement parentContainer;
	private static InputEvent _currentEvent;
	private static UIElement focusedElement;

	private static RealmVertex[] panel;
	private static RealmArenaAllocator allocator;

	static void initialize()
	{
		allocator = new RealmArenaAllocator(2048);
		panelImage = readImageBytes("$EngineAssets/Images/ui-panel.png");
		pressedButtonImage = readImageBytes("$EngineAssets/images/ui-button-pressed.png");
		sliderImage = readImageBytes("$EngineAssets/images/ui-slider.png");
		panelMesh = loadMesh("$EngineAssets/Models/ui-panel.obj");
		panelMesh.calculateTangents();
		uiProgram = ShaderLibrary.getShader("$EngineAssets/Shaders/ui.shader");
		textProgram = ShaderLibrary.getShader("$EngineAssets/Shaders/text.shader");
		UIMaterial.initialze();
		UIMaterial.reserve(32);
		UIMaterial.allocate(512,512);
		uiBatch = new Batch!(RealmVertex)(MeshTopology.TRIANGLE,uiProgram,11);
		uiBatch.setShaderStorageCallback(&(UIMaterial.bindShaderStorage));
		uiBatch.initialize(UIMaterial.allocatedVertices(),UIMaterial.allocatedElements());
		uiBatch.reserve(32);
		TextMaterial.initialze();
		TextMaterial.reserve(32);
		TextMaterial.allocate(512,512);
		textBatch = new Batch!(RealmVertex)(MeshTopology.TRIANGLE,textProgram,11);
		textBatch.setShaderStorageCallback(&(TextMaterial.bindShaderStorage));
		textBatch.initialize(TextMaterial.allocatedVertices(),TextMaterial.allocatedElements());
		textBatch.reserve(32);
		
		Tuple!(int,int) windowSize = RealmApp.getWindowSize();
		uiCamera = new Camera(CameraProjection.ORTHOGRAPHIC,vec2(windowSize[0],windowSize[1]),-1,100,0);
		uiCamera.projBounds = ProjectionWindowBounds.ZERO_TO_ONE;
		font = Font.load(VirtualFS.getSystemPath("$EngineAssets/Fonts/arial.ttf"));
		parentContainer = createElement(vec3(0),vec3(1),vec3(0));

		containerStack = new Stack!(UIElement)(32,allocator);
		themeStack = new Stack!(UITheme)(8,allocator);
		containerPush(parentContainer);
		themePush(UITheme(vec4(1),vec4(1)));
		InputManager.registerInputEventCallback(&inputEvent);

		panel.length = panelMesh.positions.length;

	}

	static bool inputEvent(InputEvent event)
	{
		_currentEvent = event;
		return true;
	}

	
	static UIElement createElement(Transform transform)
	{
		TextureDesc desc =TextureDesc(ImageFormat.SRGBA8,TextureFilterfunc.LINEAR,TextureWrapFunc.CLAMP_TO_BORDER);
		Texture2D texture = new Texture2D(&panelImage);
		return createElement(transform,texture,desc);
	}
	static UIElement createElement(vec3 position, vec3 scale, vec3 rotation)
	{

		TextureDesc desc =TextureDesc(ImageFormat.SRGBA8,TextureFilterfunc.LINEAR,TextureWrapFunc.CLAMP_TO_BORDER);
		Texture2D texture = new Texture2D(&panelImage);
		return createElement(position,scale,rotation,texture,desc);

	}

	static UIElement createElement(ref Transform transform, Texture2D texture, TextureDesc textureDesc)
	{
		UIMaterial material = new UIMaterial;
		material.setShaderProgram(uiProgram);
		material.textures.settings = textureDesc;
		material.textures.baseTexture = texture;
		material.packTextureAtlas();
		material.color = vec4(1,1,1,1);	
		UIElement element = {randomUUID()};
		UIElements.transforms[element] = transform;
		UIElements.materials[element] = material;
		return element;
	}

	

	static UIElement createElement(vec3 position, vec3 scale, vec3 rotation, Texture2D texture,TextureDesc textureDesc)
	{
		UIMaterial material = new UIMaterial;
		material.setShaderProgram(uiProgram);
		material.textures.settings = textureDesc;
		material.textures.baseTexture = texture;
		material.packTextureAtlas();
		material.color = vec4(1,1,1,1);
		Transform transform = new Transform(position ,rotation,scale);		
		UIElement element = {randomUUID()};
		UIElements.transforms[element] = transform;
		UIElements.materials[element] = material;
		return element;
	}

	private static void newTextPanel(UIElement element)
	{
		TextMaterial material = new TextMaterial;
		material.color = vec4(1);
		TextElements.materials[element] = material;
		TextElements.transforms[element] = UIElements.transforms[element];
		material.setShaderProgram(textProgram);
		if(element !in TextElements.strings)
		{
			TextElements.strings[element] = "";
		}
		if(element !in TextElements.layouts)
		{
			TextElements.layouts[element] = TextLayout(4,6,12);
		}
		
	}


	static void deleteElement(UIElement element)
	{
		if(element in UIElements.materials)
		{
			UIMaterial material = UIElements.materials[element];
			UIElements.materials.remove(element);
			UIElements.transforms.remove(element);
			destroy!(false)(material);
			
		}
		if(element in TextElements.materials)
		{
			TextMaterial material = TextElements.materials[element];
			TextElements.materials.remove(element);
			TextElements.transforms.remove(element);
			destroy!(false)(material);
			
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
	
	static float slider(UIElement element,float value)
	{
		drawPanel(element);
		Transform transform = UIElements.transforms[element];
		float progress = clamp(value,0.0f,1.0f);
		if(element !in SliderElements.sliders)
		{
			vec3 size = vec3(25,25,transform.scale.z);
			vec3 position = transform.position - vec3((transform.scale.x/2) - (size.x/2),0,0);
			
			Texture2D sliderTexture = new Texture2D(&sliderImage);
			TextureDesc desc =TextureDesc(ImageFormat.SRGBA8,TextureFilterfunc.LINEAR,TextureWrapFunc.CLAMP_TO_BORDER);
			UIElement newSlider = createElement(position,size,transform.getRotationEuler(),sliderTexture,desc);
			SliderElements.sliders[element] = newSlider;
			SliderElements.sliderHeld[element] = false;

		}
		containerPush(element);
		UIElement slider = SliderElements.sliders[element];
		Transform sliderTransform = UIElements.transforms[slider];
		float x = transform.scale.x/-2 + (transform.scale.x/2 - transform.scale.x/-2) * progress;
		sliderTransform.position = vec3(x,0,0);
		ButtonState sliderState = button(slider);
		if(sliderState == ButtonState.PRESSED && SliderElements.sliderHeld[element] == false)
		{
			SliderElements.sliderHeld[element] = true;
			SliderElements.lastMousePosition = Vector!(double,2)(_currentEvent.mouseEvent.x,_currentEvent.mouseEvent.y);
			
		}
		else if(SliderElements.sliderHeld[element])
		{
			if(_currentEvent.mouseEvent.state == KeyState.Release)
			{
				
				SliderElements.sliderHeld[element] = false;
			}
			
		}
		if(SliderElements.sliderHeld[element])
		{
			if(InputManager.getMouseButton(RealmMouseButton.ButtonLeft) == KeyState.Press)
			{
				Vector!(double,2) currentMousePosition = Vector!(double,2)(InputManager.getMouseAxis(MouseAxis.X),0);
				auto difference = currentMousePosition - SliderElements.lastMousePosition;
				
				
				SliderElements.lastMousePosition = currentMousePosition;
				progress += (difference.x/2) / (transform.scale.x/2);
				Logger.LogInfo("%f",progress);
			}
		}
		containerPop();
		return clamp(progress,0.0f,1.0f);


	}

	static T dropdown(T)(UIElement element, string[T] options, T selectedOption)
	{
		if(element !in DropdownElements.showOptions)
		{
			DropdownElements.showOptions[element] =  false;
		}
		T newOption = selectedOption;
		drawTextString(element,options[selectedOption]);
		Transform selectedTransform = UIElements.transforms[element];
		UIMaterial material = UIElements.materials[element];
		RealmVertex[] selectedVertices = panelVertices(selectedTransform,material);
		containerPush(element);
		if(mouseOverElement(element,selectedVertices) && _currentEvent.action == InputActionType.MouseAction)
		{
			
			DropdownElements.showOptions[element] = true;

		}
		if(DropdownElements.showOptions[element])
		{
			
			if(element !in DropdownElements.shownOptions)
			{
				DropdownElements.shownOptions[element] = new UIElement[](options.length);
				int numOptions = 0;
				for(int i = 1; i <= options.length;i++)
				{
					if(options.keys[i-1] != selectedOption)
					{
						numOptions++;
						vec3 position = vec3(0,-selectedTransform.scale.y * numOptions,0);

						DropdownElements.shownOptions[element][i-1] = createElement(position,selectedTransform.scale,vec3(0));
					}
					
				}

			}
			UIElement[] dropdownOptions = DropdownElements.shownOptions[element];
			foreach(index,option; enumerate(options.values))
			{
				if(options.keys[index] != selectedOption)
				{
					UIElement optionElement = dropdownOptions[index];
					if(button(optionElement,option) == ButtonState.RELEASED)
					{
						newOption = options.keys[index];
					}
				}
				
			}
		}
		if(newOption != selectedOption)
		{
			if(element in DropdownElements.shownOptions)
			{
				UIElement[] dropdownOptions = DropdownElements.shownOptions[element];
				foreach(option;dropdownOptions)
				{
					deleteElement(option);
					DropdownElements.shownOptions.remove(element);
				}
			}
			
			DropdownElements.showOptions[element] = false;
		}
		containerPop();
		return newOption;


	}
	

	static void drawTextString(T...)(UIElement element,string text,T t )
	{
		import std.algorithm.comparison;
		import std.format : format;
		
		drawPanel(element);
		
		
		if(element!in TextElements.materials)
		{
			newTextPanel(element);
			
		}
		TextLayout layout = TextElements.layouts[element];
		TextMaterial material = TextElements.materials[element];
		font.setPixelSize(0,layout.fontSize);
		TextElements.transforms[element] = UIElements.transforms[element];
		Transform transform = TextElements.transforms[element];
		material = TextElements.materials[element];
		SamplerObject!(TextureType.TEXTURE2D)* materialAtlas = material.getTextureAtlas();
		materialAtlas.textureDesc = TextureDesc(ImageFormat.RED8,TextureFilterfunc.LINEAR,TextureWrapFunc.CLAMP_TO_BORDER);
		string formatted = text.format(t);
		int numCharsFit =cast(int)( transform.scale.x / cast(float) layout.fontSize);
		string justified = leftJustify(formatted,numCharsFit);
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

	
	

	static ButtonState button(UIElement element)
	{
		Transform transform = UIElements.transforms[element];
		UIMaterial material = UIElements.materials[element];

		RealmVertex[] panelVertices = panelVertices!(UIMaterial)(transform,material);

		ButtonState result = ButtonState.NONE;
		if(mouseOverElement(element,panelVertices) && _currentEvent.action == InputActionType.MouseAction)
		{
			if(_currentEvent.mouseEvent.state == KeyState.Press)
			{
				
				material.color = vec4(0.8);
				result = ButtonState.PRESSED;
			}
			
			else if(_currentEvent.mouseEvent.state == KeyState.Release)
			{
				
				material.color = vec4(0.9);
				result = ButtonState.RELEASED;
			}
			else
			{
				result = ButtonState.HOVER;
				
			}

		}
		else
		{
			
			material.color = vec4(1);
		}

		drawPanel(element);
		return result;
	}

	static ButtonState button(UIElement element,string text)
	{
		
		
		ButtonState result = button(element);
		drawTextString(element,text);
		
		return result;

	}

	static private RealmVertex[] panelVertices(Mat)(Transform transform,Mat material)
	in
	{
		static assert(isMaterial!(Mat));
	}
	do
	{
		
		RealmVertex[] vertices = panel.dup;
		//vertices.length = panelMesh.positions.length;
		Transform parent = UIElements.transforms[containerStack.peek()];
		scope Transform copy = new Transform(transform);
		copy.position += parent.position;
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
			
			material.color= theme.textColor;
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




	static string textBox(UIElement element)
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
		
		if(element !in TextElements.materials)
		{
			newTextPanel(element);
		}
		TextMaterial textMaterial = TextElements.materials[element];
		TextLayout layout = TextElements.layouts[element];
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
					if(_currentEvent.keyEvent.key == RealmKey.Backspace)
					{
						text = text.chop();
					}
					
				}
				
			}
		}
		
		
		
		drawTextString(element,text);
		return text;
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

		element = containerStack.peek();
		transform.position -= UIElements.transforms[element].position;
		transform.scale -= UIElements.transforms[element].scale;
		transform.rotation -= UIElements.transforms[element].rotation;
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
		Renderer.get.globalData.projectionMatrix[0..$] = vp.value_ptr[0..16].dup;
		Renderer.get.globalData.viewMatrix[0..$] = mat4.identity.transposed.value_ptr[0..16];
		GraphicsSubsystem.updateGlobalData(Renderer.get.globalData);
		uiBatch.drawBatch!(false,PrimitiveShape.TRIANGLE);
		textBatch.drawBatch!(false,PrimitiveShape.TRIANGLE);
		uiBatch.resetBatch();
		textBatch.resetBatch();
		GraphicsSubsystem.enableDepthTest();
		_currentEvent.action = InputActionType.None;
		
		
		
	}
}
