
#version 460 core

layout(std140, binding = 0) uniform _reGloblaData
{
	mat4 _vp;

};



out vec4 outColor; 
in vec4 Color;
in RESurfaceData
{
	vec3 posWS;
	vec4 posCS;

} RESurfaceDataOut;

void main()
{ 
	outColor = Color;
}