module realm.engine.input;
import glfw3.api;
import core.stdc.stdio;

class InputManager
{
    import std.stdio;
    private static GLFWwindow* window;


    

    

    alias KeyCallback = void function(KeyState action, int key) nothrow @nogc;
	alias ScrollCallback = void function(double xoffset, double yoffset) nothrow @nogc;
    private static KeyCallback keyEvent;
	private static ScrollCallback scrollEvent;
	private static double scrollX;
	private static double scrollY;
	static this()
	{
		scrollX = 0;
		scrollY = 0;
	}

    static KeyState getKey(RealmKey key)
	{
        int state = glfwGetKey(window,key);
        switch(state)
		{
            case GLFW_PRESS:
                return KeyState.Press;
            case GLFW_RELEASE:
                return KeyState.Release;
            default:
                return KeyState.Press;
		}

	}

	static double getMouseAxis(MouseAxis axis)
	{
		double x;
		double y;
		glfwGetCursorPos(window,&x,&y);
		switch(axis)
		{
			case MouseAxis.X:
				return x;
			case MouseAxis.Y:
				return y;
			default:
				return x;
		}
	}

	static double getMouseScroll(ScrollOffset offset)
	{
		switch(offset)
		{
			case ScrollOffset.X:
				return scrollX;
			case ScrollOffset.Y:
				return scrollY;
			default:
				return 0.0f;

		}
	}

	static KeyState getMouseButton(RealmMouseButton button)
	{
		int state = glfwGetMouseButton(window,button);
		switch(state)
		{
            case GLFW_PRESS:
                return KeyState.Press;
            case GLFW_RELEASE:
                return KeyState.Release;
            default:
                return KeyState.Press;
		}
	}
    
	extern(C) static void internalScrollCallback(GLFWwindow* window, double x, double y) nothrow @nogc
	{
		scrollX = x;
		scrollY = y;
		
	}


	void setScrollCallback(ScrollCallback cb)
	{
		scrollEvent = cb;
	}


    static void initialze(GLFWwindow* w)
    {
		window = w;
		glfwSetScrollCallback(w,&internalScrollCallback);
    }

}

enum KeyState
{
	Press,
	Release
}

enum MouseAxis
{
	X,
	Y
}

enum ScrollOffset
{
	X,
	Y
}

enum RealmMouseButton : int
{
	ButtonLeft = GLFW_MOUSE_BUTTON_LEFT,
	ButtonRight = GLFW_MOUSE_BUTTON_RIGHT,

}

enum RealmKey : int
{
	Space =	GLFW_KEY_SPACE,        
	Apostrophe = GLFW_KEY_APOSTROPHE ,   
	Comma =GLFW_KEY_COMMA ,        
	Minus =GLFW_KEY_MINUS ,        
	Period =GLFW_KEY_PERIOD ,       
	Slash =GLFW_KEY_SLASH ,        
	Zero = GLFW_KEY_0 ,            
	One = GLFW_KEY_1 ,            
	Two = GLFW_KEY_2 ,            
	Three = GLFW_KEY_3 ,            
	Four = GLFW_KEY_4 ,            
	Five = GLFW_KEY_5 ,            
	Six = GLFW_KEY_6 ,            
	Seven = GLFW_KEY_7 ,            
	Eight = GLFW_KEY_8 ,            
	Nine = GLFW_KEY_9 ,            
	Semicolon = GLFW_KEY_SEMICOLON ,    
	Equal = GLFW_KEY_EQUAL ,        
	A = GLFW_KEY_A ,            
	B = GLFW_KEY_B ,            
	C = GLFW_KEY_C ,            
	D = GLFW_KEY_D ,            
	E = GLFW_KEY_E ,            
	F = GLFW_KEY_F ,            
	G = GLFW_KEY_G ,            
	H = GLFW_KEY_H ,            
	I = GLFW_KEY_I ,            
	J = GLFW_KEY_J ,            
	K = GLFW_KEY_K ,            
	L = GLFW_KEY_L ,            
	M = GLFW_KEY_M ,            
	N = GLFW_KEY_N ,            
	O = GLFW_KEY_O ,            
	P = GLFW_KEY_P ,            
	Q = GLFW_KEY_Q ,            
	R = GLFW_KEY_R ,            
	S = GLFW_KEY_S ,            
	T = GLFW_KEY_T ,            
	U = GLFW_KEY_U ,            
	V = GLFW_KEY_V ,            
	W = GLFW_KEY_W ,            
	X = GLFW_KEY_X ,            
	Y = GLFW_KEY_Y ,            
	Z = GLFW_KEY_Z ,            
	LeftBracket = GLFW_KEY_LEFT_BRACKET , 
	Backslash = GLFW_KEY_BACKSLASH ,    
	RightBracket = GLFW_KEY_RIGHT_BRACKET ,
	GraveAccent = GLFW_KEY_GRAVE_ACCENT , 
	World1 = GLFW_KEY_WORLD_1 ,      
	World2 = GLFW_KEY_WORLD_2 ,      
	Escape = GLFW_KEY_ESCAPE ,       
	Enter = GLFW_KEY_ENTER ,        
	Tab = GLFW_KEY_TAB ,          
	Backspace = GLFW_KEY_BACKSPACE ,    
	Insert = GLFW_KEY_INSERT ,       
	Delete = GLFW_KEY_DELETE ,       
	Right = GLFW_KEY_RIGHT ,        
	Left = GLFW_KEY_LEFT ,         
	Down = GLFW_KEY_DOWN ,         
	Up = GLFW_KEY_UP ,           
	PgUp = GLFW_KEY_PAGE_UP ,      
	PgDown = GLFW_KEY_PAGE_DOWN ,    
	Home = GLFW_KEY_HOME ,         
	End = GLFW_KEY_END ,          
	CapsLock = GLFW_KEY_CAPS_LOCK ,    
	ScrollLock = GLFW_KEY_SCROLL_LOCK ,  
	NumLock = GLFW_KEY_NUM_LOCK ,     
	PrtScr = GLFW_KEY_PRINT_SCREEN , 
	Pause = GLFW_KEY_PAUSE ,        
	F1  = GLFW_KEY_F1 ,           
	F2  = GLFW_KEY_F2 ,           
	F3  = GLFW_KEY_F3 ,           
	F4  = GLFW_KEY_F4 ,           
	F5  = GLFW_KEY_F5 ,           
	F6  = GLFW_KEY_F6 ,           
	F7  = GLFW_KEY_F7 ,           
	F8  = GLFW_KEY_F8 ,           
	F9  = GLFW_KEY_F9 ,           
	F10 = GLFW_KEY_F10 ,          
	F11 = GLFW_KEY_F11 ,          
	F12 = GLFW_KEY_F12 ,          
	F13 = GLFW_KEY_F13 ,          
	F14 = GLFW_KEY_F14 ,          
	F15 = GLFW_KEY_F15 ,          
	F16 = GLFW_KEY_F16 ,          
	F17 = GLFW_KEY_F17 ,          
	F18 = GLFW_KEY_F18 ,          
	F19 = GLFW_KEY_F19 ,          
	F20 = GLFW_KEY_F20 ,          
	F21 = GLFW_KEY_F21 ,          
	F22 = GLFW_KEY_F22 ,          
	F23 = GLFW_KEY_F23 ,          
	F24 = GLFW_KEY_F24 ,          
	F25 = GLFW_KEY_F25 ,          
	KeyPad0 = GLFW_KEY_KP_0 ,         
	KeyPad1 = GLFW_KEY_KP_1 ,         
	KeyPad2 = GLFW_KEY_KP_2 ,         
	KeyPad3 = GLFW_KEY_KP_3 ,         
	KeyPad4 = GLFW_KEY_KP_4 ,         
	KeyPad5 = GLFW_KEY_KP_5 ,         
	KeyPad6 = GLFW_KEY_KP_6 ,         
	KeyPad7 = GLFW_KEY_KP_7 ,         
	KeyPad8 = GLFW_KEY_KP_8 ,         
	KeyPad9 = GLFW_KEY_KP_9 ,         
	KeyPadDecimal = GLFW_KEY_KP_DECIMAL ,   
	KeyPadDivide = GLFW_KEY_KP_DIVIDE ,    
	KeyPadMultiply = GLFW_KEY_KP_MULTIPLY ,  
	KeyPadSubtract = GLFW_KEY_KP_SUBTRACT ,  
	KeyPadAdd = GLFW_KEY_KP_ADD ,       
	KeyPadEnter = GLFW_KEY_KP_ENTER ,     
	KeyPadEqual = GLFW_KEY_KP_EQUAL ,     
	Shift = GLFW_KEY_LEFT_SHIFT ,   
	Control = GLFW_KEY_LEFT_CONTROL , 
	Alt = GLFW_KEY_LEFT_ALT ,     
	Super = GLFW_KEY_LEFT_SUPER ,   
	RightShift = GLFW_KEY_RIGHT_SHIFT ,  
	RightControl = GLFW_KEY_RIGHT_CONTROL ,
	RightAlt = GLFW_KEY_RIGHT_ALT ,    
	RightSuper = GLFW_KEY_RIGHT_SUPER ,  
	Menu = GLFW_KEY_MENU ,         
	Last = GLFW_KEY_LAST ,         

}