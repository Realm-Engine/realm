#version 460 core
layout(location = 0) in vec3 v_Position;
layout(location = 1) in vec2 v_TexCoord;
layout(location =2) in vec3 v_Normal;
layout(location = 3) in vec3 v_Tangent;
struct DirectionalLight
{
        vec4 direction;
        vec4 color;
};


layout(std140, binding = 0) uniform _reGloblaData
{
	mat4 u_vp;
    DirectionalLight mainLight;
        

};

struct ObjectData
{
	vec4 color;
	float oceanLevel;

};

struct REVertexData
{
	vec3 position;
	vec2 texCoord;
	vec3 normal;
	vec3 tangent;
	ObjectData objectData;
	int objectId;

};

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

} RESurfaceDataOut;

uniform sampler2D atlasTextures[16];



vec2 samplerUV(vec4 to)
{
	return (v_TexCoord * vec2(to.x,to.y)) + vec2(to.z,to.w);
}

mat3 calculateTBN()
{
	vec3 T = normalize(v_Tangent);
	vec3 N = normalize(v_Normal);
	vec3 B = normalize(cross(N,T));
	return mat3(T,B,N);


}

vec4 vert(REVertexData IN)
{
	
	
	float oceanLevel = IN.objectData.oceanLevel;
	vec3 position = IN.position + vec3(0,oceanLevel,0);

	RESurfaceDataOut.TBN = calculateTBN();
	RESurfaceDataOut.objectData = IN.objectData;
	RESurfaceDataOut.objectId = IN.objectId;
	RESurfaceDataOut.posCS = transpose(u_vp) * vec4(position, 1.0);
	RESurfaceDataOut.posWS = v_Position;
	RESurfaceDataOut.texCoord = IN.texCoord;
	RESurfaceDataOut.normal = IN.normal;
	return RESurfaceDataOut.posCS;
	


}
void main()
{
	REVertexData vertexData;
	vertexData.tangent = v_Tangent;
	vertexData.position = v_Position;
	vertexData.texCoord = v_TexCoord;
	vertexData.normal = v_Normal;
	vertexData.objectData = data[gl_DrawID];
	vertexData.objectId = gl_DrawID;
	gl_Position = vert(vertexData);
	
}


