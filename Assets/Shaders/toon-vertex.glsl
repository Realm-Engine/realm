#version 460 core

layout(location = 0) in vec3 v_Position;

out gl_PerVertex
{
	vec4 gl_Position;
};

out RESurfaceData
{
    vec3 posWS;
} RESurfaceDataOut;

void main()
{

    gl_Position = vec4(v_Position,1.0);
}