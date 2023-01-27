#version 460 core

layout (location = 0) out vec4 FragColor;

layout(binding = 1) uniform MaterialBlock
{
    vec4 baseColor;
};

layout(std140, binding = 0) uniform _reGloblaData
{
	mat4 u_vp;
};

in RESurfaceData
{
    vec3 posWS;
} RESurfaceDataIn;

void main()
{
    FragColor = baseColor;

}