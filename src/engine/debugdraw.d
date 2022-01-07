module realm.engine.debugdraw;
import realm.engine.graphics.batch;
import realm.engine.graphics.graphicssubsystem;
import realm.engine.graphics.core;
import realm.engine.core;
import realm.engine.app;
import realm.engine.asset;
import realm.engine.graphics.material;
import std.range;
static class Debug
{
	private static Batch!(RealmVertex) debugBatch;
	private static ShaderProgram debugProgram;
	alias DebugMaterialLayout = Alias!(["color" : UserDataVarTypes.VECTOR]);
	alias DebugMaterial = Alias!(Material!(DebugMaterialLayout));
	private static DebugMaterial debugMaterial;
	private static VertexAttribute[] vertex3DAttributes;
	static void initialze()
	{
		
		VertexAttribute position = {VertexType.FLOAT3,0,0};
		VertexAttribute texCoord = {VertexType.FLOAT2,12,1};
		VertexAttribute normal = {VertexType.FLOAT3,20,2};
		VertexAttribute tangent = {VertexType.FLOAT3,32,3};
		vertex3DAttributes ~= position;
		vertex3DAttributes ~= texCoord;
		vertex3DAttributes ~= normal;
		vertex3DAttributes ~= tangent;

		debugProgram = loadShaderProgram("./src/engine/Assets/Shaders/debug.shader","Debug");
		
		DebugMaterial.initialze();
		DebugMaterial.reserve(16);
		DebugMaterial.allocate(1024,1024);
		debugMaterial = new DebugMaterial;
		debugMaterial.setShaderProgram(debugProgram);
		debugMaterial.packTextureAtlas();
		debugBatch = new Batch!(RealmVertex)(MeshTopology.LINES,debugProgram,10);
		debugBatch.setShaderStorageCallback(&(DebugMaterial.bindShaderStorage));
		debugBatch.initialize(vertex3DAttributes,DebugMaterial.allocatedVertices(),DebugMaterial.allocatedElements());
		debugMaterial.color = vec4(1,0,0,1);
		debugBatch.reserve(16);
		

	}

	static void drawLine(vec3 start, vec3 end)
	{
		RealmVertex startVertex;
		RealmVertex endVertex;
		startVertex.position = start;
		startVertex.texCoord = vec2(0,0);
		startVertex.normal =vec3(0,1,0);
		startVertex.tangent = vec3(0,0,1);
		endVertex.position = end;
		endVertex.texCoord = vec2(0,0);
		endVertex.normal =vec3(0,1,0);
		endVertex.tangent = vec3(0,0,1);
		debugBatch.submitVertices!(DebugMaterial)([startVertex,endVertex],[0,1],debugMaterial);
	}

	

	static void drawBox(vec3 origin,float width, float height,float length)
	{

		//Bottom face
		RealmVertex[] vertices;
		vertices.length = 8;

		vertices[0].position = vec3(origin.x - width/2,origin.y - height/2,origin.z - length/2);
		vertices[1].position = vec3(origin.x - width/2,origin.y - height/2,origin.z + length/2);
		vertices[2].position = vec3(origin.x + width/2, origin.y - height/2,origin.z + length/2);
		vertices[3].position = vec3(origin.x + width/2,origin.y - height/2,origin.z - length/2);

		vertices[4].position = vec3(origin.x - width/2,origin.y + height/2,origin.z - length/2);
		vertices[5].position = vec3(origin.x - width/2,origin.y + height/2,origin.z + length/2);
		vertices[6].position = vec3(origin.x + width/2, origin.y + height/2,origin.z + length/2);
		vertices[7].position = vec3(origin.x + width/2,origin.y + height/2,origin.z - length/2);


		uint[] bottom = [0,1,1,2,2,3,3,0];
		uint[] front = [1,5,5,6,6,2,2,1];
		uint[] left = [0,4,4,5,5,1,1,0];
		uint[] right = [3,7,7,6,6,2,2,3];
		uint[] back = [0,4,4,7,7,3,3,0];
		uint[] top =[4,5,5,6,6,7,7,4];

		foreach(i,v;vertices.enumerate(0))
		{
			vertices[i].normal = vec3(0,-1,0);
			vertices[i].texCoord = vec2(0,0);
			vertices[i].tangent = vec3(0,0,-1);
		}
		debugBatch.submitVertices!(DebugMaterial)(vertices,bottom ~ front ~ left ~ right ~ back ~ top,debugMaterial);


	}

	static void flush()
	{
		
		debugBatch.drawBatch!(false,PrimitiveShape.LINES)();
		debugBatch.resetBatch();
	}
	



}
