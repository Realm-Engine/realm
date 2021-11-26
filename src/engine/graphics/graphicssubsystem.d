module realm.engine.graphics.graphicssubsystem;
import realm.engine.graphics.opengl;
import realm.engine.graphics.core;
import realm.engine.core;
import gl3n.linalg;
import realm.engine.graphics.core;
import std.container.array;
class GraphicsSubsystem
{
	private VertexBuffer!float vertexBuffer;
	private ElementBuffer elementBuffer;
	private VertexArrayObject vao;
	private DrawIndirectCommandBuffer cmdBuffer;
	private ShaderBlock globalDataBuffer;
	private RealmGlobalData globalData;
	this()
	{
		cmdBuffer.create();

		vao.create();
		vao.bind();
		vertexBuffer.create();
		elementBuffer.create();
		vertexBuffer.bind();
		VertexAttribute attr = {VertexType.FLOAT3,0,0,AttributeSlot.POSITION};
		bindAttribute(attr);
		elementBuffer.bind();
		cmdBuffer.bind();
		vertexBuffer.store(32);
		elementBuffer.store(32);
		cmdBuffer.store(6);
		vao.unbind();
		vertexBuffer.unbind();
		elementBuffer.unbind();
		cmdBuffer.unbind();
		
		globalData.viewProjection = mat4.identity;
		globalDataBuffer.create();
		globalDataBuffer.bind();
		globalDataBuffer.bindBase(0);
		globalDataBuffer.store(1);
		globalDataBuffer.bufferData(&globalData,1);
		globalDataBuffer.unbind();

	}

	void drawMeshIndirect(Mesh mesh,MeshTopology topology = MeshTopology.TRIANGLE)
	{

		vao.bind();
		vertexBuffer.bind();
		cmdBuffer.bind();
		DrawElementsIndirectCommand indirect;
		float[] positions;
		positions.length = mesh.positions.length * 3;
		for(int i = 0; i < mesh.positions.length;i++)
		{
			int idx = (i*3);
			positions[idx..(idx+3)] = mesh.positions[i].vector;

		}

		indirect.count = cast(uint)mesh.faces.length;
		indirect.firstIndex = 0;
		indirect.instanceCount = 2;
		indirect.baseVertex = 0;
		indirect.baseInstance = 0;
		vertexBuffer.bufferData(positions.ptr,positions.length);
		elementBuffer.bufferData(mesh.faces.ptr,mesh.faces.length);
		cmdBuffer.bufferData(&indirect,1);
		drawIndirect();
		vao.unbind();
	}


	void drawMultiMeshIndirect(Mesh[] meshes,MeshTopology topology = MeshTopology.TRIANGLE)
	{
		
		uint vtxOffset = 0;
		uint idxOffset = 0;
		uint currentVertex = 0;
		for(int i =0; i < meshes.length;i++)
		{
			Mesh mesh = meshes[i];
			float[] positions;
			positions.length = mesh.positions.length * 3;
			for(int j = 0; j < mesh.positions.length;j++)
			{
				int idx = (j*3);
				positions[idx..(idx+3)] = mesh.positions[j].vector;

			}

			DrawElementsIndirectCommand indirect;
			indirect.count = cast(uint)mesh.faces.length;
			indirect.firstIndex = idxOffset;
			indirect.baseVertex = currentVertex;
			indirect.baseInstance = 0;
			indirect.instanceCount = (cast(uint)mesh.faces.length / topology);
			vertexBuffer.bufferData(positions.ptr,positions.length);
			elementBuffer.bufferData(mesh.faces.ptr,mesh.faces.length);
			cmdBuffer.bufferData(&indirect,1);
			vtxOffset += positions.length;
			idxOffset += mesh.faces.length;
			currentVertex += (positions.length / topology);
			
		}
		drawMultiIndirect(cast(int)meshes.length);
		vao.unbind();

	}
	
	
	void beginDraw()
	{
		vao.bind();
		vertexBuffer.bind();
		cmdBuffer.bind();
	}

	void endDraw()
	{
		vao.unbind();
		vertexBuffer.invalidate();
		elementBuffer.invalidate();
		cmdBuffer.invalidate();
	}





}
