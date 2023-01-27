#version 460 core

layout (location = 0) out vec4 FragColor;

layout(std430, binding = 0) buffer DrawContext
{
    mat4 u_view;
    mat4 u_projection;
};

layout(std140,binding = 1) uniform MaterialBlock
{
    vec4 baseColor;
};



in RESurfaceData
{
    vec3 posWS;
} RESurfaceDataIn;

void main()
{
    FragColor = baseColor;

}