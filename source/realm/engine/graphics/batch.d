module realm.engine.graphics.batch;
import realm.engine.graphics.opengl;
import realm.engine.graphics.core;
import realm.engine.graphics.graphicssubsystem;
import realm.engine.graphics.material;
import realm.engine.graphics.renderer;
import realm.engine.logging;
import std.range;
import std.format;
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
	private SamplerObject!(TextureType.TEXTURE2D)*[] textureAtlases;
	alias BindShaderStorageCallback = void function();
	private BindShaderStorageCallback bindShaderStorage;
	private int order;
	private ShaderPipeline shaderPipeline;

	@property renderOrder()
	{
		return order;
	}
	this(MeshTopology topology,ShaderProgram program,int order)
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
		shaderPipeline.useProgramStages(ShaderProgramStages.VERTEX_STAGE,program);
		shaderPipeline.useProgramStages(ShaderProgramStages.FRAGMENT_STAGE,program);
		
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
		cmdBuffer.unbind();

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
		//foreach(attribute; attributes)
		//{
		//
		//    bindAttribute(attribute,stride);
		//}
		allocateBuffers(initialElements,numFaces);
		vertexBuffer.unbind();
		elementBuffer.unbind();

	}

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
		
	void allocateBuffers(uint numElements,uint numFaces)
	{
		vertexBuffer.store(numElements * bufferAmount);
		elementBuffer.store(numFaces * bufferAmount);
		this.capacity = numElements;

		
	}
	void submitVertices(Mat)(T[] vertices, uint[] faces, Mat material)
	{
		
		static assert(isMaterial!(Mat));
		uint elementOffset = ( cmdBufferBase * (capacity * topology)) + numIndicesInFrame;
		uint offset = ( cmdBufferBase * capacity) + numVerticesInFrame;
		vertexBuffer.ptr[offset.. offset + vertices.length] = vertices;
		elementBuffer.ptr[elementOffset .. elementOffset + faces.length] = faces;
		DrawElementsIndirectCommand cmd;
		cmd.count = cast(uint)faces.length;
		cmd.instanceCount =cast(uint) faces.length / topology;
		cmd.firstIndex = numIndicesInFrame;
		cmd.baseVertex = numVerticesInFrame;
		cmd.baseInstance = 0;
		cmdBuffer.ptr[( cmdBufferBase) * (maxElementsInFrame )  + numElementsInFrame] = cmd;
		
		numElementsInFrame++;
		numVerticesInFrame+=vertices.length;
		numIndicesInFrame+=faces.length;
		material.writeUniformData();
		textureAtlases~=material.getTextureAtlas();
	}


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
			program.setUniformInt(3 + i,texture.slot);

		}
		SamplerObject!(TextureType.TEXTURE2D)* cameraDepth;
		SamplerObject!(TextureType.TEXTURE2D)* cameraScreen;
		cameraDepth =&Renderer.getMainFrameBuffer().fbAttachments[FrameBufferAttachmentType.DEPTH_ATTACHMENT].texture;
		cameraDepth.setActive(0);
		program.setUniformInt(0,0);
		cameraScreen = &Renderer.getMainFrameBuffer().fbAttachments[FrameBufferAttachmentType.COLOR_ATTACHMENT].texture;
		cameraScreen.setActive(1);
		program.setUniformInt(1,1);
		if(renderShadows)
		{
			GraphicsSubsystem.getShadowMap().setActive(2);


			program.setUniformInt(2,2);
		}
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



	void resetBatch()
	{
		cmdBufferBase = (cmdBufferBase + 1) % bufferAmount;
		numElementsInFrame = 0;
		numVerticesInFrame = 0;
		numIndicesInFrame = 0;
		textureAtlases.length = 0;
		
	}



}

