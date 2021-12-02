module realm.engine.graphics.renderer;
import realm.engine.graphics.batch;
import realm.engine.graphics.graphicssubsystem;
import realm.engine.graphics.core;
import realm.engine.core;
import gl3n.linalg;
class Renderer
{
	import std.container.array;
	import std.stdio;
	private Batch!RealmVertex batch;
	VertexAttribute[] vertex3DAttributes;
	private RealmGlobalData globalData;
	private Camera* camera;

	@property activeCamera(Camera* cam)
	{
		camera = cam;
	}


	this()
	{
		
		GraphicsSubsystem.initialze();
		GraphicsSubsystem.setClearColor(126,32,32,true);
		globalData.viewProjection = mat4.identity;
		GraphicsSubsystem.updateGlobalData(&globalData);
		VertexAttribute position = {VertexType.FLOAT3,0,0,AttributeSlot.POSITION};
		vertex3DAttributes ~= position;
		batch = new Batch!RealmVertex(MeshTopology.TRIANGLE);
		batch.initialize(vertex3DAttributes,64);
		batch.reserve(3);

	}

	void submitMesh(Mesh mesh,Transform transform)
	{
		batch.bindBuffers();
		
		RealmVertex[uint] vertexData;
		//writeln(transform.model);
		mat4 modelMatrix = transform.model;
		//writeln(modelMatrix);
		foreach(index; mesh.faces)
		{
			RealmVertex vertex;
			
			vertex.position = vec3(modelMatrix * vec4(mesh.positions[index],1.0));
			
			/*vertex.normal = mesh.normals[index];
			vertex.uv = mesh.textureCoordinates[index];*/
			vertexData[index] = vertex;
			



		}
		//batch.allocateBuffers(cast(uint)vertexData.length);
		batch.submitVertices(vertexData.values,mesh.faces);

		batch.unbindBuffers();
		
	}

	void update()
	{
		GraphicsSubsystem.clearScreen();
		if(camera !is null)
		{
			camera.updateViewProjection();
			globalData.viewProjection = camera.viewProjection;
		}
		GraphicsSubsystem.updateGlobalData(&globalData);
		batch.drawBatch();
		
	}

	void flush()
	{
		
	}

	

}