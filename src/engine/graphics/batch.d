module realm.engine.graphics.batch;
import realm.engine.graphics.opengl;
import realm.engine.graphics.core;
import realm.engine.graphics.graphicssubsystem;
class Batch(T)
{
	import std.algorithm.iteration : fold,map;
	import std.container.array;
	import std.stdio;
	private VertexArrayObject vao;
	private VertexBuffer!(T,BufferUsage.Buffered) vertexBuffer;
	private ElementBuffer!(BufferUsage.Buffered) elementBuffer;
	


	private DrawIndirectCommandBuffer!(BufferUsage.MappedWrite) cmdBuffer;
	private uint numElementsInFrame;
	private uint capacity;
	private MeshTopology topology;
	private uint cmdBufferBase;
	private uint bufferAmount;
	private DrawElementsIndirectCommand* cmdBufferMap;
	private DrawElementsIndirectCommand* cmdBufferMapOffset;
	private uint maxElementsInFrame;
	this(MeshTopology topology)
	{
		this.topology = topology;
		vao.create();
		vertexBuffer.create();
		elementBuffer.create();
		cmdBuffer.create();
		this.numElementsInFrame= 0;
		this.capacity = 0;
		cmdBufferBase = 0;
		bufferAmount =2;
		maxElementsInFrame = 0;
		
	}

	void reserve(size_t amount)
	{
		this.maxElementsInFrame = cast(uint)amount;
		cmdBuffer.bind();
		cmdBuffer.store(amount * bufferAmount);
		cmdBufferMap = cmdBuffer.ptr; 
		cmdBuffer.unbind();
	}


	void initialize(VertexAttribute[] attributes,uint initialElements)
	{
		this.capacity = initialElements;
		vao.bind();
		vertexBuffer.bind();
		elementBuffer.bind();

		uint stride = attributes.map!((a) => shaderVarBytes( a.type)).fold!((a,b) => a+b);
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
	void submitVertices(T[] vertices, uint[] faces)
	{
		uint vtxPos = vertexBuffer.bufferData(vertices.ptr,vertices.length);
		uint idxPos = elementBuffer.bufferData(faces.ptr,faces.length);
		DrawElementsIndirectCommand cmd;
		cmd.count = cast(uint)faces.length;
		cmd.instanceCount =cast(uint) faces.length / topology;
		cmd.firstIndex = idxPos;
		cmd.baseVertex = vtxPos / topology;
		cmd.baseInstance = 0;
		//cmdBufferMapOffset = cmdBufferMap + cmdBufferBase + numElementsInFrame;
		//cmdBufferMapOffset = cmd;
		cmdBufferMap[cmdBufferBase * maxElementsInFrame  + numElementsInFrame] = cmd;
		numElementsInFrame++;
		//cmdBufferMapOffset = cmdBufferMap + cmdBufferBase + numElementsInFrame;
	}

	void drawBatch()
	{
		int cmdTypeSize = cast(int)DrawElementsIndirectCommand.sizeof;
		bindBuffers();
		uint offset = cmdBufferBase * (maxElementsInFrame * cmdTypeSize);
		//writeln(offset);
		GraphicsSubsystem.drawMultiElementsIndirect(offset, numElementsInFrame);
		unbindBuffers();
		cmdBufferBase = (cmdBufferBase + 1) % bufferAmount;
		numElementsInFrame = 0;

		
		
	}

}

