
#version 460 core

layout(std140, binding = 0) uniform _reGloblaData
{
	mat4 _vp;

};

struct ObjectData
{
	vec4 color;
	vec4 albedo;
};

layout (std430,binding = 1) buffer _perObjectData
{
	ObjectData data[];
};

uniform sampler2D atlasTextures[16];

out vec4 outColor; 
in vec4 Color;
in RESurfaceData
{
	vec3 posWS;
	vec4 posCS;
	vec2 texCoord;
	flat int drawId;
	ObjectData objectData;

} RESurfaceDataOut;

vec2 samplerUV(vec4 to)
{
	return (RESurfaceDataOut.texCoord * vec2(to.x,to.y)) + vec2(to.z,to.w);
}

void main()
{ 
	vec4 albedo = RESurfaceDataOut.objectData.albedo;
	vec2 albedoUv = (RESurfaceDataOut.texCoord * vec2(albedo.x,albedo.y)) + vec2(albedo.z,albedo.w);
	
	outColor = Color * texture(atlasTextures[RESurfaceDataOut.drawId],albedoUv);
}