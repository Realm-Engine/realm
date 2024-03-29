

layout(location = 0) in vec3 v_Position;
layout(location = 1) in vec2 v_TexCoord;
layout(location = 2) in vec3 v_Normal;
layout(location = 3) in vec3 v_Tangent;
layout(location = 4) in int v_MaterialID;

out gl_PerVertex
{
	vec4 gl_Position;
};

layout (std140,binding = 1 ) uniform _perObjectData
{
	Material data[16];
};

layout(std140, binding = 2) uniform _objectToWorld
{
	mat4 objectToWorld[16];
};


out RESurfaceData
{
	vec3 posWS;
	vec4 posCS;
	vec2 texCoord;
	flat int objectId;
	//Material material;
	vec3 normal;
	mat3 TBN;
	/*vec4 lightSpacePosition;
	vec4 eyeSpacePosition;*/

		
} RESurfaceDataOut;


struct REVertexData
{
	vec3 position;
	vec2 texCoord;
	vec3 normal;
	//Material material;
	int objectId;
	vec3 tangent;

};


vec4 vertex(REVertexData IN);

mat3 calculateTBN(vec3 tangent, vec3 normal)
{
	vec3 T = normalize(tangent);
	vec3 N = normalize(normal);
	T = normalize(T - dot(T,N) * N);

	vec3 B = normalize(cross(N,T));
	return mat3(T,B,N);
}

#define objectTexture atlasTextures[v_MaterialID]
#define getObjectData(v) data[RESurfaceDataIn.objectId].v
#define OBJECT_TO_WORLD_T transpose(OBJECT_TO_WORLD)
#define OBJECT_TO_WORLD objectToWorld[gl_DrawID]


void main()
{
	REVertexData vertexData;
	vertexData.tangent =  v_Tangent;
	vertexData.position = v_Position;
	vertexData.texCoord = v_TexCoord;
	vertexData.normal = v_Normal;
	//vertexData.material = data[v_MaterialID];
	vertexData.objectId = v_MaterialID;
	
	gl_Position = vertex(vertexData);
	
	
}