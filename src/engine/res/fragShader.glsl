
#version 430 core

layout(std140, binding = 0) uniform _reGloblaData
{
	mat4 _vp;

};
out vec4 outColor; 

in RESurfaceData
{
	vec3 posWS;
	vec4 posCS;

} RESurfaceDataOut;

void main()
{ 
	outColor = vec4(1.0,0,0,1.0);
}