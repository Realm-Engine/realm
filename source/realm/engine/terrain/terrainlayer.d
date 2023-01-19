module realm.engine.terrain.terrainlayer;
import realm.engine.graphics.renderlayer;
import realm.engine.graphics.renderpass;
import realm.engine.graphics.core;
import realm.engine.core;
import realm.engine.graphics.material;
struct TerrainInfo
{
	int meshResolution;
	Transform transform;
}

alias TerrainMaterial = Alias!(Material!(["ambient" : UserDataVarTypes.TEXTURE2D]));

class TerrainLayer : RenderLayer
{
	
	private StandardShaderModel terrainShader;
	private VertexArrayObject vao;
	private VertexBuffer!(RealmVertex,BufferStorageMode.Immutable) vertexBuffer;
	private ElementBuffer!(BufferStorageMode.Immutable) elementBuffer;
	private DrawIndirectCommandBuffer!(BufferStorageMode.Immutable) cmdBuffer;
	private ShaderBlock!(float[16], BufferStorageMode.Immutable) objectToWorldMats;
	private SamplerObject!(TextureType.TEXTURE2D)*[] textureAtlases;
	private uint numVertices;
	private uint numIndices;
	private uint numElements;

	override void initialize()
	{

	}

	void generateTerrain(TerrainInfo terrainInfo)
	{
		Mesh plane = generateFace(vec3(0,1,0),terrainInfo.meshResolution);


	}

	override void renderBegin()
	{

	}
	void onDraw(string RenderpassName,Renderpass)(Renderpass pass) if(RenderpassName == "geometryPass" || RenderpassName == "lightPass")
	{

	}
	override void renderEnd()
	{

	}
}

Mesh generateFace(vec3 normal, int resolution)
{
	vec3 axisA = vec3(normal.y,normal.z,normal.x);
	vec3 axisB = normal.cross(axisA);
	vec3[] vertices = new vec3[](resolution * resolution);
	uint[] faces = new uint[]((resolution - 1) * (resolution - 1)  * 6);
	vec2[] uv = new vec2[](resolution * resolution);
	int triIndex = 0;
	for(int y = 0; y < resolution;y++)
	{
		for(int x = 0; x < resolution; x++)
		{
			int vertexIndex = x + y * resolution;
			vec2 t = vec2(x,y) / (resolution - 1.0f);
			vec3 point = normal + axisA * (2 * t.x -1) + axisB * (2 * t.y - 1);
			vertices[vertexIndex] = point;
			uv[vertexIndex] = t;
			if(x != resolution -1 && y != resolution - 1)
			{
				faces[triIndex + 0] = vertexIndex;
				faces[triIndex + 1] = vertexIndex + resolution + 1;
				faces[triIndex + 2] = vertexIndex + resolution;
				faces[triIndex + 3] = vertexIndex;
				faces[triIndex + 4] = vertexIndex + 1;
				faces[triIndex + 5] = vertexIndex + resolution + 1;
				triIndex +=6;
			}
		}
	}
	Mesh mesh;
	mesh.positions = vertices;
	mesh.textureCoordinates = uv;
	mesh.faces = faces;
	mesh.normals = new vec3[](mesh.positions.length);
	mesh.normals[0..$] = normal;

	mesh.calculateTangents();
	return mesh;

}