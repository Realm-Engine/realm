module realm.engine.graphics;
import std.stdio;
import std.concurrency : receive, receiveOnly,
    send, spawn, thisTid, Tid;

import realm.engine.memory;
import derelict.opengl3.gl3;
import glfw3.api;
import core.atomic : atomicOp, atomicLoad;
import realm.engine.app;
import realm.engine.internal.glutils;


class OpenGLObject
{
	private uint id;
	shared @property ID(){return id;}
	
	alias id this;
	shared void setId(uint id)
	{
		this.id = id;
	}
}

struct RenderMessage{}
struct InitialzeRenderer{}
struct StopRenderer{}
struct Sync{}
struct StartFrame{}
struct RenderJob
{
	immutable float[] vertices;
	immutable uint[] faces;

}
struct EndFrame{}





synchronized private class RendererWorker
{
	
	private shared(OpenGLObject) vao;
	private shared(OpenGLObject) vbo;
	private shared(OpenGLObject) ibo;
	
	

	void bufferVertexData(immutable float[] data)
	{
		bufferDataUtil!float(GL_ARRAY_BUFFER,data,GL_DYNAMIC_DRAW);
	}
	void bufferIndexData(immutable uint[] data)
	{
		bufferDataUtil!uint(GL_ELEMENT_ARRAY_BUFFER,data,GL_DYNAMIC_DRAW);

	}

	void drawTriangles(ulong elements)
	{
		glDrawElements(GL_TRIANGLES,cast(int)elements,GL_UNSIGNED_INT,null);
	}

	void bind()
	{

	}

	static private void handleStartFrame(StartFrame ev,const shared(RendererWorker)* worker)
	{
		glBindVertexArray(worker.vao);
		
		glClear(GL_COLOR_BUFFER_BIT);
		glClearColor(0.5,0.5,0.5,1.0);

	}



	static private void handleEndFrame(EndFrame ef, const shared(RendererWorker)* worker)
	{
		clearBufferUtil(GL_ARRAY_BUFFER,GL_DYNAMIC_DRAW);

		clearBufferUtil(GL_ELEMENT_ARRAY_BUFFER,GL_DYNAMIC_DRAW);
		glBindVertexArray(0);
		glfwSwapBuffers(RealmApp.window);
		
		
	}

	static private void handleRenderJob(RenderJob job, shared (RendererWorker)* worker)
	{
		worker.bufferVertexData(job.vertices);
		worker.bufferIndexData(job.faces);
		worker.drawTriangles(job.faces.length);
		scope(failure)
		{
			synchronized
			{
				writeln("Render failed");
			}
			
		}
	}


	static private void handleInit(InitialzeRenderer ir,shared(RendererWorker)* worker)
	{
		DerelictGL3.load();
		glfwMakeContextCurrent(RealmApp.window);
		auto loaded = DerelictGL3.reload(GLVersion.GL43,GLVersion.GL45);
		uint vao;
		writeln("Making vao");
		glGenVertexArrays(1,&vao);
		worker.vao = new shared(OpenGLObject);
		worker.vbo = new shared(OpenGLObject);
		worker.ibo = new shared(OpenGLObject);
		worker.vao = vao;
		glBindVertexArray(worker.vao);
		uint* buffers = new uint;
		glGenBuffers(2,buffers);
		worker.vbo = buffers[0];
		worker.ibo = buffers[1];
		glBindBuffer(GL_ARRAY_BUFFER,worker.vbo);
		glBindBuffer(GL_ELEMENT_ARRAY_BUFFER,worker.ibo);
		clearBufferUtil(GL_ARRAY_BUFFER,GL_DYNAMIC_DRAW);
		clearBufferUtil(GL_ELEMENT_ARRAY_BUFFER,GL_DYNAMIC_DRAW);
		glEnableVertexAttribArray(0);
		glVertexAttribPointer(0,3,GL_FLOAT,GL_FALSE,3 * float.sizeof,cast(void*)0);

		glBindVertexArray(0);
		
	}

	static private void start(Tid parent,shared(RendererWorker)* worker)
	{
		bool cancelled = false;
		while(!cancelled)
		{
			receive(
					(InitialzeRenderer ir){handleInit(ir,worker);},
					(StopRenderer sr){cancelled = true;writeln("Stopping renderer");},
					(StartFrame sf){handleStartFrame(sf,worker);},
					(RenderJob job){handleRenderJob(job,worker);},
					(EndFrame ef){handleEndFrame(ef,worker);}
			);
			Sync sync;
			send(parent,sync);
		}

	}
}


class Renderer
{
	private Tid renderThread;
	shared(RendererWorker) worker;

	this()
	{
		worker = new shared(RendererWorker);
		renderThread = spawn(&RendererWorker.start,thisTid,&worker);
		InitialzeRenderer init;
		
		sendMessage(init);
		waitForSync();
		writeln(worker.vao.ID);
		
	}

	void sendMessage(T)(T message)
	{
		
		send(renderThread,message);
	}

	void waitForSync()
	{
		bool done = false;
		while(!done)
		{
			receive((Sync sync)
					{
						done = true;
						
					});
			
		}
	}
	
	void beginDraw()
	{
		StartFrame sf;
		sendMessage(sf);
		waitForSync();
	}

	void endDraw()
	{
		EndFrame ef;
		sendMessage(ef);
		waitForSync();
	}

	void drawMesh(immutable float[] mesh,immutable uint[] faces)
	{
		RenderJob job = {mesh,faces};
		//job.vertices = mesh;
		sendMessage(job);
		waitForSync();
	}

	void stopRenderer()
	{
		StopRenderer sr;
		send(renderThread,sr);
	}

	~this()
	{
		
	}
}