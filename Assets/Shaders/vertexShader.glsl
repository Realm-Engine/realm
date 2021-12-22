#version 460 core
layout(location = 0) in vec3 v_Position;
layout(location = 1) in vec2 v_TexCoord;
layout(location =2) in vec3 v_Normal;

layout(std140, binding = 0) uniform _reGloblaData
{
	mat4 u_vp;

};

struct ObjectData
{
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
	vec3 normal;

} RESurfaceDataOut;


void main()
{
	RESurfaceDataOut.objectData = data[gl_DrawID];
	RESurfaceDataOut.drawId = gl_DrawID;
	RESurfaceDataOut.posCS = transpose(u_vp) * vec4(v_Position, 1.0);
	RESurfaceDataOut.posWS = v_Position;
	RESurfaceDataOut.texCoord = v_TexCoord;
	RESurfaceDataOut.normal = v_Normal;
	gl_Position = RESurfaceDataOut.posCS;
	
}

