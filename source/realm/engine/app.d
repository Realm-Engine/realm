module realm.engine.app;

public import derelict.opengl3.gl3;
public import realm.engine.graphics;

import std.stdio;

import std.conv;
import std.meta;

import std.typecons;
import core.memory;
import realm.engine.graphics.core : enableDebugging;
import realm.engine.logging;
import realm.engine.asset;
struct RealmInitDesc
{
    int width;
    int height;
    string title;
    pipeline.InitPipelineFunc initPipelineFunc;
    
}

alias RealmInit = RealmInitDesc function(string[] args);
alias RealmUpdate = bool function(float);
alias RealmStart = void function();



mixin template RealmMain(RealmInit initFunc,RealmStart startFunc,RealmUpdate updateFunc)
{
    import glfw3.api;
    
    public static string root;
    public static __gshared GLFWwindow* window;

    private pipeline.GraphicsContext defaultUpdateContext(pipeline.GraphicsContext currentCtx)
    {
        
        return currentCtx;
    }

    private pipeline.PipelineInitDesc defaultPipelineInit()
    {
        import gl3n.linalg;
        pipeline.GraphicsContext ctx;
        ctx.viewMatrix = mat4.identity.value_ptr[0..16];
        ctx.projectionMatrix = mat4.identity.value_ptr[0..16];
        pipeline.PipelineInitDesc desc;
        desc.initialContext = ctx;
        desc.clearColor = [1,1,1,1];
        desc.updateContext = &defaultUpdateContext;
        return desc;

    }

    void main(string[] args)
	{
        bool shutdown;

        RealmInitDesc initDesc = initFunc(args);

        Logger.Assert(initDesc.width >= 0 && initDesc.height >=0,"Width and height of app are negative");
        shutdown = false;
        Logger.LogInfo("Starting GLFW");
        auto result = glfwInit();
        Logger.Assert(result == 1,"Failed to initialze GLFW");
        glfwWindowHint(GLFW_OPENGL_DEBUG_CONTEXT,true);
        window = glfwCreateWindow(initDesc.width, initDesc.height, initDesc.title.ptr, null, null);
        Logger.Assert(window !is null,"Could not create GLFW window");
        DerelictGL3.load();

        glfwMakeContextCurrent(window);

        
        GLVersion glVer = DerelictGL3.reload(GLVersion.GL43,GLVersion.GL45);
        Logger.LogInfo("Loaded OpenGL Version %d",glVer);
        
        glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);
        glfwSwapInterval(1);
        


        //ShaderLibrary.loadDir("$EngineAssets/");
        

        startFunc();
        
        pipeline.InitPipelineFunc initPipelineDesc = &defaultPipelineInit;

        if(initDesc.initPipelineFunc !is null)
        {
            initPipelineDesc = initDesc.initPipelineFunc;
        }

        

        pipeline.init(initPipelineDesc());
        

        scope(exit)
		{
            Logger.LogInfo("Cleaning up");
            if(window)
			{
                glfwDestroyWindow(window);
			}
            glfwTerminate();
		}
        
        while(!shutdown)
		{
            pipeline.startFrame();
            glfwPollEvents();
            shutdown = updateFunc(0.0f) || glfwWindowShouldClose(window);
            glfwSwapBuffers(window);
            pipeline.endFrame();
		}
        
        

	}
}