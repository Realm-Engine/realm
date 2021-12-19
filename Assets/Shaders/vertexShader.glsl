#version 460 core
layout(location = 0) in vec3 v_Position;
layout(location = 1) in vec2 v_TexCoord;

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

out RESurfaceData
{
	vec3 posWS;
	vec4 posCS;
	vec2 texCoord;
	flat int drawId;
	ObjectData objectData;

} RESurfaceDataOut;

out vec4 Color;

void main()
{
	RESurfaceDataOut.objectData = data[gl_DrawID];
	Color = data[gl_DrawID].color;
	RESurfaceDataOut.drawId = gl_DrawID;
	RESurfaceDataOut.posCS = _vp * vec4(v_Position, 1.0);
	RESurfaceDataOut.posWS = v_Position;
	RESurfaceDataOut.texCoord = v_TexCoord;
	gl_Position = RESurfaceDataOut.posCS;
	
}

