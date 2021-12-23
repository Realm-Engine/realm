#version 460 core
layout(location = 0) in vec3 v_Position;
layout(location = 1) in vec2 v_TexCoord;
layout(location =2) in vec3 v_Normal;

layout(std140, binding = 0) uniform _reGloblaData
{
	mat4 u_vp;

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

} RESurfaceDataOut;

uniform sampler2D atlasTextures[16];

sampler2D textureAtlas()
{
	return atlasTextures[gl_DrawID];
}

vec2 samplerUV(vec4 to)
{
	return (v_TexCoord * vec2(to.x,to.y)) + vec2(to.z,to.w);
}

vec4 vert(REVertexData IN)
{
	
	
	vec4 heightSample =texture(textureAtlas(),samplerUV(IN.objectData.heightMap));
	float height = (heightSample.x);
	height = clamp(height,IN.objectData.oceanLevel,1.0);
	height = height * IN.objectData.heightStrength;
	vec3 position = v_Position + vec3(0,height,0);
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
	vertexData.position = v_Position;
	vertexData.texCoord = v_TexCoord;
	vertexData.normal = v_Normal;
	vertexData.objectData = data[gl_DrawID];
	vertexData.objectId = gl_DrawID;
	gl_Position = vert(vertexData);
	
}


