
layout(location = 0) in vec3 v_Position;
layout(location = 1) in vec2 v_TexCoord;
layout(location =2) in vec3 v_Normal;
layout(location =3) in vec3 v_Tangent;


layout (std430,binding = 1) buffer _perObjectData
{
	ObjectData data[];
};


out RESurfaceData
{
	vec3 posWS;
	vec4 posCS;
	vec2 texCoord;
	flat int objectId;
	ObjectData objectData;
	vec3 normal;
	mat3 TBN;
	vec4 lightSpacePosition;
} RESurfaceDataOut;


struct REVertexData
{
	vec3 position;
	vec2 texCoord;
	vec3 normal;
	ObjectData objectData;
	int objectId;
	vec3 tangent;

};


vec4 vertex(REVertexData IN);

mat3 calculateTBN()
{
	vec3 T = normalize(v_Tangent);
	vec3 N = normalize(v_Normal);
	vec3 B = normalize(cross(N,T));
	return mat3(T,B,N);
}

#define objectTexture atlasTextures[gl_DrawID]

void main()
{
	REVertexData vertexData;
	vertexData.tangent = v_Tangent;
	vertexData.position = v_Position;
	vertexData.texCoord = v_TexCoord;
	vertexData.normal = v_Normal;
	vertexData.objectData = data[gl_DrawID];
	vertexData.objectId = gl_DrawID;
	
	gl_Position = vertex(vertexData);
	
}