#version 430 core
layout(location = 0) in vec3 v_Position;
out RESurfaceData
{
	vec3 posWS;

} RESurfaceDataOut;

void main()
{
	RESurfaceDataOut.posWS = v_Position;
	gl_Position = vec4(v_Position,1.0);
	
}

