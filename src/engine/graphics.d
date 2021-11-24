module realm.engine.graphics;
import realm.engine.app;
import realm.engine.internal.glutils;
import realm.engine.core;
import realm.engine.exceptions;
import std.stdio;
import std.concurrency : receive, receiveOnly,
    send, spawn, thisTid, Tid;

import realm.engine.memory;
import derelict.opengl3.gl3;
import glfw3.api;
import core.atomic : atomicOp, atomicLoad;

import std.algorithm.iteration;
import gl3n.linalg;
import std.format : format;
import std.string : toStringz,fromStringz;

synchronized class OpenGLObject
{
	private uint id;
	shared @property ID(){return id;}
	shared @property ID(int value){id = value;}
	alias id this;
	shared this()
	{
		id = uint.max;
	}
	
}

class ShaderProgram : OpenGLObject
{
	private uint vertexID;
	private uint fragmentID;
	shared @property uint vertex() {return vertexID;}
	shared @property void vertex(uint value) {vertexID = value;}

	shared @property uint fragment() {return fragmentID;}
	shared @property void fragment(uint value) {fragmentID = value;}

	

	shared this()
	{
		this.vertexID = uint.max;
		this.fragmentID = uint.max;
	}
	shared this(uint vertexID, uint fragmentID)
	{
		this.vertexID = vertexID;
		this.fragmentID = fragmentID;
	}
	
	

}






struct RenderMessage{}
struct InitialzeRenderer{}
struct StopRenderer{}
struct Sync{}
struct StartFrame{}
struct UseShaderProgram{immutable uint program;}
struct RenderJob
{
	immutable vec3[] vertices;
	immutable uint[] faces;
	
}

struct EndFrame{}

struct CreateShaderProgram
{
	immutable string fragmentSource;
	immutable string vertexSource;
	shared(ShaderProgram)* program;
}

enum RendererResult
{
	SUCCESS,
	FAILURE
};

template RResult()
{
	struct
	{
		RendererResult result;
	}

}

struct CreateShaderProgramResult
{
	mixin RResult;

}



struct Error
{
	immutable string message;
}


enum ShaderType : GLenum
{
	VERTEX = GL_VERTEX_SHADER,
	FRAGMENT = GL_FRAGMENT_SHADER
}



synchronized private class RendererWorker
{
	
	private shared(OpenGLObject) vao;
	private shared(OpenGLObject) vbo;
	private shared(OpenGLObject) ibo;
	
	

	void bufferVertexData(immutable vec3[] data)
	{
		
		float[] buffer;
		buffer.length = data.length * 3;
		for(int i = 0; i < data.length; i++)
		{
			float[3] vector = data[i].vector;
			buffer[(i * 3)..((i*3)+3)] = vector;
		}
		bufferDataUtil!float(GL_ARRAY_BUFFER,buffer,GL_DYNAMIC_DRAW);
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

	static private void safePrint(T...)(T args)
	{
		synchronized
		{
			writeln(args);
		}
	}
	
	inout(uint) compileShader(inout(string) source, ShaderType type)
	{	
		GLenum shaderType = type;
		uint shId = glCreateShader(type);
		auto cstr = toStringz(source);
		const(char*)[] arr;
		arr~= cstr;
		glShaderSource(shId, 1, arr.ptr,null);
		glCompileShader(shId);
		int status;
		glGetShaderiv(shId,GL_COMPILE_STATUS,&status);
		scope(failure)
		{
			return uint.max;
		}
		if(status == GL_FALSE)
		{
			int length = -1;
			glGetShaderiv(shId,GL_INFO_LOG_LENGTH,&length);
			char[] message;
			if(length > -1)
			{
				message.length = length;
				glGetShaderInfoLog(shId,length,&length,message.ptr);
				char[] dstr = fromStringz(message);

				if(type == ShaderType.VERTEX)
				{
					throw new ShaderCompileError("Vertex shader",dstr);
				}
				else
				{
					throw new ShaderCompileError("Fragment shader",dstr);
				}
			}

		}

		return shId;
	}

	void linkProgram(shared(ShaderProgram)* program)
	{
		immutable uint programID = glCreateProgram();
		program.ID = programID;

		glAttachShader(programID,program.vertex);
		glAttachShader(programID,program.fragment);
		glLinkProgram(programID);
		glDeleteShader(program.vertex);
		glDeleteShader(program.fragment);

		
	}

	CreateShaderProgramResult compileProgram(immutable string fragmentSource, immutable string vertexSource,shared(ShaderProgram)* program)
	{

		try
		{
			immutable uint fragSh = compileShader(fragmentSource,ShaderType.FRAGMENT);
			immutable uint vertSh = compileShader(vertexSource,ShaderType.VERTEX);
			CreateShaderProgramResult result = {RendererResult.SUCCESS};
			program.vertex = vertSh;
			program.fragment = fragSh;
			return result;
		}
		catch(ShaderCompileError e)
		{
			safePrint(e.msg);
			program.vertex = uint.max;
			program.fragment = uint.max;
			CreateShaderProgramResult result = {RendererResult.FAILURE};
			return result;
		}


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
		glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 4);
		glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3);
		glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);
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
			Sync sync;
			
			receive(
					(InitialzeRenderer ir){handleInit(ir,worker);send(parent,sync);},
					(StopRenderer sr)
					{
						cancelled = true;
						safePrint("Stopping renderer");
						send(parent,sync);
					},
					(StartFrame sf){handleStartFrame(sf,worker);send(parent,sync);},
					(RenderJob job){handleRenderJob(job,worker);send(parent,sync);},
					(EndFrame ef){handleEndFrame(ef,worker);send(parent,sync);},
					(CreateShaderProgram ev){
						CreateShaderProgramResult result = worker.compileProgram(ev.fragmentSource,ev.vertexSource,ev.program);
						worker.linkProgram(ev.program);
						send(parent,result);
						
					},
					(UseShaderProgram ev)
					{
						glUseProgram(ev.program);
					}
			);
			
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
			receive(
					(Sync sync){done = true;},
					(Error e) {done = true; writeln(e.message);});
			
		}
	}

	void waitForResult(T)(void delegate(T) handler)
	{
		bool done = false;
		while(!done)
		{
			receive((T ev){
				handler(ev);
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
	
	

	void drawMesh(Mesh mesh)
	{
		immutable uint[] faces = mesh.faces.idup;
		immutable vec3[] positions= mesh.positions.idup;
		RenderJob job = {positions,faces};
		sendMessage(job);
		waitForSync();
		
	}

	void useShaderProgram(shared(ShaderProgram)* program)
	{
		UseShaderProgram ev = {program.ID};
		sendMessage(ev);
		

	}
	

	void drawMesh(Mesh mesh, mat4 model)
	{
		vec3[] positions;
		foreach(vec; mesh.positions)
		{
			positions ~= vec3(model * vec4(vec,1.0));
		}
		immutable uint[] faces = mesh.faces.idup;
		RenderJob job = {positions.idup,faces};
		sendMessage(job);
		waitForSync();

	}


	private void compileShaderProgramResult(CreateShaderProgramResult result)
	{

	}
	void compileShaderProgram(immutable string vertexSource, immutable string fragmentSource,shared(ShaderProgram)* program)
	{
		CreateShaderProgram ev = {fragmentSource,vertexSource,program};
		sendMessage(ev);
		void handleResult(CreateShaderProgramResult result)
		{
			if(result.result == RendererResult.SUCCESS)
			{
				writeln("Shader program compiled");
			}
			else
			{
				writeln("Could not compile shader program");
				
			}

		}


		waitForResult!CreateShaderProgramResult(&handleResult);

	}

	void stopRenderer()
	{
		
		StopRenderer sr;
		send(renderThread,sr);
		waitForSync();
	}

	~this()
	{
		stopRenderer();
	}
}