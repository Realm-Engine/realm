module realm.engine.graphics.graphicssubsystem;
import realm.engine.graphics.opengl;
import realm.engine.graphics.core;
import realm.engine.core;
import gl3n.linalg;
import realm.engine.graphics.core;
import std.container.array;
import realm.engine.graphics.batch;
import derelict.opengl3.gl3;


alias BufferUsage = GBufferUsage;

class GraphicsSubsystem
{
	

	private static ShaderBlock globalDataBuffer;


	static void setClearColor(float r, float g, float b, bool normalize)
	{
		vec3 color = vec3(r,g,b);
		if(normalize)
		{
			color /= 255;
		}
		
		glClearColor(color.x,color.y,color.z,0.0);

	}

	static this()
	{
	}
	
	static void initialze()
	{
		globalDataBuffer.create();
		globalDataBuffer.bind();
		globalDataBuffer.store(1);
		globalDataBuffer.unbind();
	}

	static void updateGlobalData(RealmGlobalData* data)
	{

		globalDataBuffer.bind();
		globalDataBuffer.bindBase(0);
		globalDataBuffer.bufferData(data,1);
		globalDataBuffer.unbind();
	}
	
	static void drawMultiElementsIndirect(DrawElementsIndirectCommand* commands,int count)
	{
		glMultiDrawElementsIndirect(GL_TRIANGLES,GL_UNSIGNED_INT,commands,count,0);
	}

	static void drawMultiElementsIndirect(int offset, int count)
	{
		glMultiDrawElementsIndirect(GL_TRIANGLES,GL_UNSIGNED_INT,cast(void*)offset,count,0);
	}
	
	static void clearScreen()
	{
		glClear(GL_COLOR_BUFFER_BIT);
		

	}

	

}
