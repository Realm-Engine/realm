#version 460 core

layout(location = 0) in vec3 v_Position;

out gl_PerVertex
{
	vec4 gl_Position;
};

layout(std430,binding = 0) buffer DrawContext
{
    mat4 u_view;
    mat4 u_projection;
};
layout(std140,binding = 1) uniform MaterialBlock
{
    vec4 baseColor;
};


out RESurfaceData
{
    vec3 posWS;
} RESurfaceDataOut;

void main()
{

    gl_Position = (u_view * u_projection) * vec4(v_Position,1.0);
}