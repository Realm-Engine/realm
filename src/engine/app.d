module realm.engine.app;
import glfw3.api;
import std.stdio;
public import derelict.opengl3.gl3;
import std.conv;



class RealmApp
{
	public static __gshared GLFWwindow* window;
	private bool shutdown;
	this(int width, int height,const char* title)
	{
		shutdown = false;
		auto result = glfwInit();
		assert(result);
		if(!result)
		{
			writeln("Failed to initialze glfw!");
		}
		
		window = glfwCreateWindow(width,height,title,null,null);
		DerelictGL3.load();
		glfwMakeContextCurrent(window);
		DerelictGL3.reload(GLVersion.GL43,GLVersion.GL45);
		glfwWindowHint(GLFW_OPENGL_PROFILE,GLFW_OPENGL_CORE_PROFILE);
		writeln("OpenGL init");
	}

	abstract void update();
	abstract void start();
	void run()
	{
		start();
		while(!shutdown)
		{
			update();
			glfwPollEvents();
			if(glfwWindowShouldClose(window))
			{
				shutdown = true;
			}
			glfwSwapBuffers(window);
			
		}
		
	}

	~this()
	{
		if(window)
		{
			glfwDestroyWindow(window);
		}
		glfwTerminate();


	}

}
