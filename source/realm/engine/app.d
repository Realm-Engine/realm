module realm.engine.app;
import glfw3.api;
import std.stdio;
public import derelict.opengl3.gl3;
import std.conv;
import std.meta;
import realm.engine.core;
import std.typecons;
import core.memory;
class RealmApp
{

    alias RealmKeyPressDelegate = void delegate(int, int);
    
    

    public static __gshared GLFWwindow* window;
    private bool shutdown;
    private const GLMAX_VER = GLVersion.GL45;
    private const GLMIN_VER = GLVersion.GL43;
    private AppMetrics appMetrics;
    
	
	struct AppMetrics
	{
        float deltaTime;
	}

    static Tuple!(int,int) getWindowSize()
	{
        int width,height;
        glfwGetWindowSize(window,&width,&height);
        return Tuple!(int,int)(width,height);

	}

    static float getTicks()
	{
        return glfwGetTime();
	}

    AppMetrics getAppMetrics()
	{
        return appMetrics;
	}


    void processArgs(string[] args)
	{
        import std.getopt;
        bool clearCache;
        foreach(arg;args)
		{
            Logger.LogInfo("Command Line Argument: %s",arg);
		}
        auto helpInformation = getopt(args,"clearCache",&clearCache);
        
        if(clearCache)
		{
           VirtualFS.clearCache();
		}
        
        
	}

    this(int width, int height, const char* title, string[] args)
    {
        Logger.Assert(width >= 0 && height >=0,"Width and height of app are negative");
        shutdown = false;
        Logger.LogInfo("Starting GLFW");
        auto result = glfwInit();
        Logger.Assert(result == 1,"Failed to initialze GLFW");
        glfwWindowHint(GLFW_OPENGL_DEBUG_CONTEXT,true);
        window = glfwCreateWindow(width, height, title, null, null);
        Logger.Assert(window !is null,"Could not create GLFW window");
        DerelictGL3.load();
        glfwMakeContextCurrent(window);
        
        GLVersion glVer = DerelictGL3.reload(GLVersion.GL43, GLVersion.GL45);
        Logger.LogInfo("Loaded OpenGL Version %d",glVer);
        
        glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);
        InputManager.initialze(window);
        glfwSwapInterval(1);
        processArgs(args);

    }
    


    abstract void update();
    abstract void start();
    
    

   

    void run()
    {
        start();
        GC.collect;
        appMetrics.deltaTime = 0;
        while (!shutdown)
        {
            InputManager.tick();
            float startTick = getTicks();
            //GC.disable();
            update();
            
            //GC.enable();
            glfwPollEvents();
            
            if (glfwWindowShouldClose(window))
            {
                shutdown = true;
            }
            glfwSwapBuffers(window);
            float endTick = getTicks();
            appMetrics.deltaTime = (endTick - startTick) * 1000;

        }

    }

    ~this()
    {
        if (window)
        {
            glfwDestroyWindow(window);
        }
        glfwTerminate();

    }

}
