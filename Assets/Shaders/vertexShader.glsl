#version 460 core
layout(location = 0) in vec3 v_Position;
layout(location = 1) in vec2 v_TexCoord;
layout(location =2) in vec3 v_Normal;
layout(location =3) in vec3 v_Tangent;
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
	vec4 heightMap;
	float heightStrength;
	float oceanLevel;
};

struct REVertexData
{
	vec3 position;
	vec2 texCoord;
	vec3 normal;
	ObjectData objectData;
	int objectId;
	vec3 tangent;

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

mat3 calculateTBN()
{
	vec3 T = normalize(v_Tangent);
	vec3 N = normalize(v_Normal);
	vec3 B = normalize(cross(N,T));
	return mat3(T,B,N);


}


vec2 samplerUV(vec4 to)
{
	return (v_TexCoord * vec2(to.x,to.y)) + vec2(to.z,to.w);
}

#define objectTexture atlasTextures[gl_DrawID]

vec4 vert(REVertexData IN)
{
	
	
	vec4 heightSample =texture(objectTexture,samplerUV(IN.objectData.heightMap));
	float height = (heightSample.x);
	//height = clamp(height,IN.objectData.oceanLevel,1.0);
	height = height * IN.objectData.heightStrength;
	vec3 position = v_Position + vec3(0,height,0);
	RESurfaceDataOut.TBN = calculateTBN();
	RESurfaceDataOut.objectData = IN.objectData;
	RESurfaceDataOut.objectId = IN.objectId;
	RESurfaceDataOut.posCS = transpose(u_vp) * vec4(position, 1.0);
	RESurfaceDataOut.posWS = position;
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


