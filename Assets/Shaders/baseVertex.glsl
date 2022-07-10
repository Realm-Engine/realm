

layout(location = 0) in vec3 v_Position;
layout(location = 1) in vec2 v_TexCoord;
layout(location =2) in vec3 v_Normal;
layout(location =3) in vec3 v_Tangent;
layout(location =4) in int v_MaterialID;

out gl_PerVertex
{
	vec4 gl_Position;
};

layout (std430,binding = 1) buffer _perObjectData
{
	Material data[];
};


out RESurfaceData
{
	vec3 posWS;
	vec4 posCS;
	vec2 texCoord;
	flat int objectId;
	Material material;
	vec3 normal;
	mat3 TBN;
	vec4 lightSpacePosition;
} RESurfaceDataOut;


struct REVertexData
{
	vec3 position;
	vec2 texCoord;
	vec3 normal;
	Material material;
	int objectId;
	vec3 tangent;

};


vec4 vertex(REVertexData IN);

mat3 calculateTBN()
{
	vec3 T = normalize(v_Tangent);
	vec3 N = normalize(v_Normal);
	T = normalize(T - dot(T,N) * N);

	vec3 B = cross(N,T);
	return mat3(T,B,N);
}

#define objectTexture atlasTextures[v_MaterialID]
#define getObjectData(v) IN.material.v



void main()
{
	REVertexData vertexData;
	vertexData.tangent = v_Tangent;
	vertexData.position = v_Position;
	vertexData.texCoord = v_TexCoord;
	vertexData.normal = v_Normal;
	vertexData.material = data[v_MaterialID];
	vertexData.objectId = v_MaterialID;
	
	gl_Position = vertex(vertexData);
	
}