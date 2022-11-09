module realm.engine.graphics.batch;
import realm.engine.graphics.opengl;
import realm.engine.graphics.core;
import realm.engine.graphics.graphicssubsystem;
import realm.engine.graphics.material;
import realm.engine.graphics.renderer;
import realm.engine.logging;
import std.range;
import std.format;
private
{
	import gl3n.linalg : mat4;
}

/**
* Mechanism for batch drawing vertices, batching is based on Material layout
* T: Structure of vertices
*/
class Batch(T)
{
	import std.algorithm.iteration : fold,map;
	import std.container.array;
	import std.stdio;
	private StandardShaderModel program;
	private VertexArrayObject vao;
	private VertexBuffer!(T,BufferStorageMode.Immutable) vertexBuffer;
	private ElementBuffer!(BufferStorageMode.Immutable) elementBuffer;

	private DrawIndirectCommandBuffer!(BufferStorageMode.Immutable) cmdBuffer;

	

	private ShaderStorage!(float[16],BufferStorageMode.Immutable) objectToWorldMats;
	private uint numElementsInFrame;
	private uint numVerticesInFrame;
	private uint numIndicesInFrame;
	private uint maxElementsInFrame;
	private uint maxIndicesInFrame;
	private uint capacity;
	private MeshTopology topology;
	private uint cmdBufferBase;
	private uint bufferAmount;

	private SamplerObject!(TextureType.TEXTURE2D)*[] textureAtlases;
	alias BindShaderStorageCallback = void function();
	private BindShaderStorageCallback bindShaderStorage;
	private int order;
	private ShaderPipeline shaderPipeline;
	alias PrepareDrawCallback = void delegate(StandardShaderModel model);
	private PrepareDrawCallback prepareDraw;
	private ulong materialId;
	@property renderOrder()
	{
		return order;
	}
	this(MeshTopology topology,StandardShaderModel program,int order)
	{
		this.order = order;
		this.topology = topology;
		shaderPipeline = new ShaderPipeline;
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
		shaderPipeline.create();
		shaderPipeline.useProgramStages(program);
		shaderPipeline.useProgramStages(program);

		objectToWorldMats.create();
		objectToWorldMats.bindBase(2);
		
		
	}

	void setShaderStorageCallback(BindShaderStorageCallback cb)
	{
		bindShaderStorage = cb;
	}

	void setPrepareDrawCallback(PrepareDrawCallback cb)
	{
		prepareDraw = cb;
	}
	void reserve(size_t amount)
	{
		this.maxElementsInFrame = cast(uint)amount;
		
		cmdBuffer.store(amount);
		
		objectToWorldMats.store(amount);

		

	}

	@property pipeline()
	{
		return shaderPipeline;
	}

	void initialize(uint initialElements,uint numFaces)
	{
		this.capacity = initialElements;
		vao.bind();
		vertexBuffer.bind();
		elementBuffer.bind();

		//uint stride = attributes.map!((a) => shaderVarElements( a.type) * shaderVarBytes(a.type)).fold!((a,b) => a+b);
		bindAttributes();
		allocateBuffers(initialElements,numFaces);
		vertexBuffer.unbind();
		elementBuffer.unbind();

	}

	/// Bind attributes as per defined by the vertex struct supplied
	void bindAttributes()
	{
		
		import std.meta;
		T vertex;
		uint stride = 0;
		
		stride += T.sizeof;
		
		int offset = 0;
		int index = 0;
		static foreach(member; __traits(allMembers,T))
		{
			
			bindAttribute!(Alias!(typeof(__traits(getMember,vertex,member))))(index,offset,stride);
			index += 1;
			offset += (typeof(__traits(getMember,vertex,member))).sizeof;
		}
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
		
	/// Allocate number of vertices and primitive elements
	void allocateBuffers(uint numElements,uint numFaces)
	{
		vertexBuffer.store(numElements * bufferAmount);
		elementBuffer.store(numFaces * bufferAmount);
		this.capacity = numElements;
		maxIndicesInFrame = numFaces;

		
	}

	void submitVertices(Mat)(T[] vertices, uint[] faces, Mat material, mat4 objectToWorld)
	{

		static assert(isMaterial!(Mat));
		uint elementOffset = ( cmdBufferBase * (maxIndicesInFrame )) + numIndicesInFrame;
		uint offset = ( cmdBufferBase * capacity) + numVerticesInFrame;
		vertexBuffer[offset .. offset + vertices.length] = vertices;
		elementBuffer[elementOffset .. elementOffset + faces.length] = faces;
		
		DrawElementsIndirectCommand cmd;
		cmd.count = cast(uint)faces.length;
		cmd.instanceCount =cast(uint) faces.length / topology;
		cmd.firstIndex = numIndicesInFrame;
		cmd.baseVertex = numVerticesInFrame;
		cmd.baseInstance = 0;
		cmdBuffer[( cmdBufferBase * maxElementsInFrame )  + numElementsInFrame] = cmd;

		numElementsInFrame++;
		numVerticesInFrame+=vertices.length;
		numIndicesInFrame+=faces.length;
		material.writeUniformData();
		textureAtlases~=material.getTextureAtlas();
		materialId = Mat.materialId();
		float[16] objectToWorldData = objectToWorld.value_ptr[0..16].dup;
		float[16]* objectToWorldPtr = &objectToWorldMats.ptr[material.instanceId];
		*objectToWorldPtr = objectToWorldData;
	}

	/// Submit mesh to add to batch
	void submitVertices(Mat)(T[] vertices, uint[] faces, Mat material)
	{
		
		static assert(isMaterial!(Mat));
		uint elementOffset = ( cmdBufferBase * (maxIndicesInFrame)) + numIndicesInFrame;
		uint offset = ( cmdBufferBase * capacity) + numVerticesInFrame;
		vertexBuffer[offset.. offset + vertices.length] = vertices;
		elementBuffer[elementOffset .. elementOffset + faces.length] = faces;
		DrawElementsIndirectCommand cmd;
		cmd.count = cast(uint)faces.length;
		cmd.instanceCount =cast(uint) faces.length / topology;
		cmd.firstIndex = numIndicesInFrame;
		cmd.baseVertex = numVerticesInFrame;
		cmd.baseInstance = 0;
		cmdBuffer[( cmdBufferBase * maxElementsInFrame )  + numElementsInFrame] = cmd;
		
		numElementsInFrame++;
		numVerticesInFrame+=vertices.length;
		numIndicesInFrame+=faces.length;
		material.writeUniformData();
		textureAtlases~=material.getTextureAtlas();
		materialId = Mat.materialId();

		
	}


	/// Initial setup prior to drawing the elements
	private uint setupDraw(bool renderShadows)()
	{
		int cmdTypeSize = cast(int)DrawElementsIndirectCommand.sizeof;
		program.use();
		bindBuffers();
		//bindAttributes();

		uint offset = cmdBufferBase * (maxElementsInFrame * cmdTypeSize);

		foreach(i,texture; textureAtlases.enumerate(0))
		{
			texture.setActive();
			program.setUniformInt(texture.slot,texture.slot);

		}
		if(prepareDraw)
		{
			prepareDraw(program);
		}
		objectToWorldMats.bindBase(2);
		if(bindShaderStorage !is null)
		{
			bindShaderStorage();
		}
		program.unbind();
		return offset;
	}

	void drawBatch(bool renderShadows = true,PrimitiveShape shape = PrimitiveShape.TRIANGLE, ShaderPipeline pipelineOverride = null)()
	{


		if(numVerticesInFrame > 0)
		{


			uint offset = setupDraw!(renderShadows)();


			shaderPipeline.bind();
			shaderPipeline.validate();
			//writeln(offset);
			GraphicsSubsystem.drawMultiElementsIndirect!(shape)(offset, numElementsInFrame);
			shaderPipeline.unbind();
			
			unbindBuffers();
		}

	}

	void drawBatch(bool renderShadows = true,PrimitiveShape shape = PrimitiveShape.TRIANGLE)(ShaderPipeline pipelineOverride)
	{


		if(numVerticesInFrame > 0)
		{


			uint offset = setupDraw!(renderShadows)();


			pipelineOverride.bind();
			pipelineOverride.validate();
			//writeln(offset);
			GraphicsSubsystem.drawMultiElementsIndirect!(shape)(offset, numElementsInFrame);
			pipelineOverride.unbind();


			unbindBuffers();
		}

	}


	/// Reset batch to initial, pre draw state, needs to be done at end of frame
	void resetBatch()
	{
		cmdBufferBase = (cmdBufferBase + 1) % bufferAmount;
		numElementsInFrame = 0;
		numVerticesInFrame = 0;
		numIndicesInFrame = 0;
		textureAtlases.length = 0;

		
		
	}



}

