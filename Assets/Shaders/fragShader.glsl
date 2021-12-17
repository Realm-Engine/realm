
#version 460 core

layout(std140, binding = 0) uniform _reGloblaData
{
	mat4 _vp;

};

struct objectData
{
	vec4 color;
};

layout (std430,binding = 1) buffer _perObjectData
{
	objectData data[];
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

} RESurfaceDataOut;

void main()
{ 
	outColor = Color * texture(atlasTextures[RESurfaceDataOut.drawId],RESurfaceDataOut.texCoord);
}