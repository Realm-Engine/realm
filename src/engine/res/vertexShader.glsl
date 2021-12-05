#version 460 core
layout(location = 0) in vec3 v_Position;


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

out RESurfaceData
{
	vec3 posWS;
	vec4 posCS;

} RESurfaceDataOut;

out vec4 Color;

void main()
{
	Color = data[gl_DrawID].color;
	RESurfaceDataOut.posCS = _vp * vec4(v_Position, 1.0);
	RESurfaceDataOut.posWS = v_Position;
	gl_Position = RESurfaceDataOut.posCS;
	
}

