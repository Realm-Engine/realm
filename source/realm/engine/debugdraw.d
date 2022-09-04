module realm.engine.debugdraw;
import realm.engine.graphics.batch;
import realm.engine.graphics.graphicssubsystem;
import realm.engine.graphics.core;
import realm.engine.core;
import realm.engine.app;
import realm.engine.asset;
import realm.engine.graphics.material;
import std.typecons;
import gl3n.linalg;
import std.range;

static class Debug
{
	
	private static Batch!(RealmVertex) debugBatch;
	private static StandardShaderModel debugProgram;
	alias DebugMaterialLayout = Alias!(["color" : UserDataVarTypes.VECTOR]);
	alias DebugMaterial = Alias!(Material!(DebugMaterialLayout));
	private static bool active;
	static void initialze()
	{
	
		active = false;
		debugProgram = loadShaderProgram("$EngineAssets/Shaders/debug.shader","Debug");
		
		DebugMaterial.initialze();
		DebugMaterial.reserve(16);
		DebugMaterial.allocate(1024,1024);
		debugBatch = new Batch!(RealmVertex)(MeshTopology.LINES,debugProgram,10);
		debugBatch.setShaderStorageCallback(&(DebugMaterial.bindShaderStorage));
		debugBatch.initialize(DebugMaterial.allocatedVertices(),DebugMaterial.allocatedElements());
		
		debugBatch.reserve(16);
		InputManager.registerInputEventCallback(&inputEvent);
		
		

	}

	static void toggleActive()
	{
		active = active ^ true;
	}

	static bool inputEvent(InputEvent e)
	{
		if(e.action == InputActionType.KeyAction)
		{
			if(e.keyEvent.state == KeyState.Release && e.keyEvent.key == RealmKey.F1)
			{
				active = active ^ true;
				return true;
			}
		}
		return false;
	}

	static void drawLine(vec3 start, vec3 end, vec3 color = vec3(0,1,0))
	{

		DebugMaterial debugMaterial = new DebugMaterial();
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
		startVertex.materialId = debugMaterial.instanceId;
		endVertex.materialId = debugMaterial.instanceId;


		debugMaterial.setShaderProgram(debugProgram);
		debugMaterial.color = vec4(color,1);
		debugBatch.submitVertices!(DebugMaterial)([startVertex,endVertex],[0,1],debugMaterial);
	}

	
	static void drawBox(vec3 origin, vec3 extent, vec3 rotation,vec3 color = vec3(1,0,0))
	{
		drawBox(origin,extent.x,extent.y,extent.z,rotation,color);
	}

	

	static void drawBox(vec3 origin,float width, float height,float length,vec3 rotation,vec3 color = vec3(1,0,0))
	{

		
		RealmVertex[8] vertices;
		

		vertices[0].position = vec3(-0.5,-0.5,-0.5);
		vertices[1].position = vec3(-0.5,-0.5,0.5);
		vertices[2].position = vec3(0.5,-0.5,0.5);
		vertices[3].position = vec3(0.5,-0.5,-0.5);

		vertices[4].position = vec3(-0.5,0.5,-0.5);
		vertices[5].position = vec3(-0.5,0.5,0.5);
		vertices[6].position = vec3(0.5,0.5,0.5);
		vertices[7].position = vec3(0.5,0.5,-0.5);

		uint[8*6] faces = [
			0,1,1,2,2,3,3,0,
			1,5,5,6,6,2,2,1,
			0,4,4,5,5,1,1,0,
			3,7,7,6,6,2,2,3,
			0,4,4,7,7,3,3,0,
			4,5,5,6,6,7,7,4,
		];
		
		mat4 rotationMatrix = quat.euler_rotation(rotation.x,rotation.y,rotation.z).to_matrix!(4,4);
		mat4 M = mat4.identity;
		M = M.scale(width,height,length);
		M *=rotationMatrix;
		M = M.translate(origin);
		DebugMaterial debugMaterial = new DebugMaterial();
		for(int i = 0; i < vertices.length; i++)
		{
			RealmVertex v = vertices[i];
			vertices[i].normal = vec3(0,-1,0);
			vertices[i].texCoord = vec2(0,0);
			vertices[i].tangent = vec3(0,0,-1);
			vertices[i].position = vec3(M *vec4(v.position,1.0) );
			vertices[i].materialId = debugMaterial.instanceId;
		}
		
		debugMaterial.color = vec4(color,1.0);
		debugMaterial.setShaderProgram(debugProgram);
		
		debugBatch.submitVertices!(DebugMaterial)(vertices,faces,debugMaterial);


	}

	static void flush()
	{
		if(active)
		{
			debugBatch.drawBatch!(false,PrimitiveShape.LINES)();

		}
		debugBatch.resetBatch();
		DebugMaterial.resetInstanceCount();

	}



}
