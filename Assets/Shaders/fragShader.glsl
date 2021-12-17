
#version 460 core

layout(std140, binding = 0) uniform _reGloblaData
{
	mat4 _vp;

};
uniform sampler2D albedo;

out vec4 outColor; 
in vec4 Color;
in RESurfaceData
{
	vec3 posWS;
	vec4 posCS;
	vec2 texCoord;

} RESurfaceDataOut;

void main()
{ 
	outColor = Color * texture(albedo,RESurfaceDataOut.texCoord);
}