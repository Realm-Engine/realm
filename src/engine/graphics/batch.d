module realm.engine.graphics.batch;
import realm.engine.graphics.opengl;
import realm.engine.graphics.core;
import realm.engine.graphics.graphicssubsystem;
import realm.engine.graphics.material;
class Batch(T)
{
	import std.algorithm.iteration : fold,map;
	import std.container.array;
	import std.stdio;
	private ShaderProgram program;
	private VertexArrayObject vao;
	private VertexBuffer!(T,BufferUsage.MappedWrite) vertexBuffer;
	private ElementBuffer!(BufferUsage.MappedWrite) elementBuffer;
	private DrawIndirectCommandBuffer!(BufferUsage.MappedWrite) cmdBuffer;
	//private ShaderStorage!(BufferUsage.MappedWrite) perObjectData;
	

	private uint numElementsInFrame;
	private uint numVerticesInFrame;
	private uint numIndicesInFrame;
	private uint capacity;
	private MeshTopology topology;
	private uint cmdBufferBase;
	private uint bufferAmount;
	private uint maxElementsInFrame;
	private SamplerObject!(TextureType.TEXTURE2D)[] textureAtlases;
	alias BindShaderStorageCallback = void function();
	private BindShaderStorageCallback bindShaderStorage;
	this(MeshTopology topology,ShaderProgram program)
	{
		this.topology = topology;
		vao.create();
		vertexBuffer.create();
		elementBuffer.create();
		cmdBuffer.create();
		this.numElementsInFrame= 0;
		this.capacity = 0;
		cmdBufferBase = 0;
		bufferAmount =1;
		maxElementsInFrame = 0;
		numVerticesInFrame = 0;
		this.program = program;
		
		
		
	}

	void setShaderStorageCallback(BindShaderStorageCallback cb)
	{
		bindShaderStorage = cb;
	}

	void reserve(size_t amount)
	{
		this.maxElementsInFrame = cast(uint)amount;
		cmdBuffer.bind();
		cmdBuffer.store(amount * bufferAmount);
		//cmdBufferMap = cmdBuffer.ptr; 
		cmdBuffer.unbind();
		/*perObjectData.bind();
		perObjectData.store(amount * bufferAmount);
		perObjectData.unbind();*/
	}


	void initialize(VertexAttribute[] attributes,uint initialElements)
	{
		this.capacity = initialElements;
		vao.bind();
		vertexBuffer.bind();
		elementBuffer.bind();

		uint stride = attributes.map!((a) => shaderVarElements( a.type) * shaderVarBytes(a.type)).fold!((a,b) => a+b);
		writeln(stride);
		foreach(attribute; attributes)
		{
			
			bindAttribute(attribute,stride);
		}
		allocateBuffers(initialElements);
		vertexBuffer.unbind();
		elementBuffer.unbind();

	}

	void bindBuffers()
	{
		vao.bind();
		vertexBuffer.bind();
		elementBuffer.bind();
		cmdBuffer.bind();
	}
	void unbindBuffers()
	{
		vao.unbind();
		elementBuffer.bind();
		cmdBuffer.unbind();
	}
		
	void allocateBuffers(uint numElements)
	{
		vertexBuffer.store(numElements);
		elementBuffer.store(numElements * topology);
		this.capacity = numElements;

		
	}
	void submitVertices(Mat)(T[] vertices, uint[] faces, Mat material)
	{
		static assert(isMaterial!(Mat));
		uint elementOffset = cmdBufferBase * (capacity * topology) + numIndicesInFrame;
		uint offset = cmdBufferBase * capacity + numVerticesInFrame;
		vertexBuffer.ptr[offset.. offset + vertices.length] = vertices;
		elementBuffer.ptr[elementOffset .. elementOffset + faces.length] = faces;
		DrawElementsIndirectCommand cmd;
		cmd.count = cast(uint)faces.length;
		cmd.instanceCount =cast(uint) faces.length / topology;
		cmd.firstIndex = numIndicesInFrame;
		cmd.baseVertex = numVerticesInFrame;
		cmd.baseInstance = 0;
		cmdBuffer.ptr[cmdBufferBase * maxElementsInFrame  + numElementsInFrame] = cmd;
		numElementsInFrame++;
		numVerticesInFrame+=vertices.length;
		numIndicesInFrame+=faces.length;
		material.writeUniformData();
		material.activateTextures();
		textureAtlases~=material.getTextureAtlas();


	}

	void drawBatch()
	{

		program.use();
		int cmdTypeSize = cast(int)DrawElementsIndirectCommand.sizeof;
		bindBuffers();
		uint offset = cmdBufferBase * (maxElementsInFrame * cmdTypeSize);
		foreach(texture; textureAtlases)
		{
			texture.setActive();
		}
		bindShaderStorage();
		//writeln(offset);
		GraphicsSubsystem.drawMultiElementsIndirect(offset, numElementsInFrame);
		unbindBuffers();
		cmdBufferBase = (cmdBufferBase + 1) % bufferAmount;
		numElementsInFrame = 0;
		numVerticesInFrame = 0;
		numIndicesInFrame = 0;
		textureAtlases.length = 0;
		
	}

}

