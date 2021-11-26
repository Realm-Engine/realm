#version 430 core
layout(location = 0) in vec3 v_Position;


layout(std140, binding = 0) uniform _reGloblaData
{
	mat4 _vp;

};

out RESurfaceData
{
	vec3 posWS;
	vec4 posCS;

} RESurfaceDataOut;

void main()
{
	RESurfaceDataOut.posCS = _vp * vec4(v_Position, 1.0);
	RESurfaceDataOut.posWS = v_Position;
	gl_Position = RESurfaceDataOut.posCS;
	
}

