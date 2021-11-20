module realm.engine.app;
import realm.engine.graphics;
import glfw3.api;
import std.stdio;
public import derelict.opengl3.gl3;
import std.conv;



class RealmApp
{
	public static __gshared GLFWwindow* window;

	Renderer renderer;
	this(int width, int height,const char* title)
	{
		
		auto result = glfwInit();
		assert(result);
		if(!result)
		{
			writeln("Failed to initialze glfw!");
		}
		
		window = glfwCreateWindow(width,height,title,null,null);

		
		renderer = new Renderer();
		

	}

	abstract void update();

	void run()
	{
		while(!glfwWindowShouldClose(window))
		{

			update();
			
			glfwPollEvents();
		}
		
	}

	~this()
	{
		renderer.destroy();
		if(window)
		{
			glfwDestroyWindow(window);
		}
		glfwTerminate();


	}

}
