
#version 430 core


out vec4 outColor; 

in RESurfaceData
{
	vec3 posWS;
}RESurfaceDataIn;

void main()
{ 
	outColor = vec4(1.0,0,0,1.0);
}