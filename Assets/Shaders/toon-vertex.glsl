#version 460 core

layout(location = 0) in vec3 v_Position;
layout(location = 1) in vec3 v_Normal;

out gl_PerVertex
{
	vec4 gl_Position;
};

layout(std430,binding = 0) buffer DrawContext
{
    mat4 u_view;
    mat4 u_projection;
    vec4 lightDirection;
};

struct Material
{
    vec4 baseColor;
    vec4 diffuse;
};
layout(std140,binding = 1) uniform PerObjectData
{
    Material material;
    mat4 modelMatrix;
};


out RESurfaceData
{
    vec3 posWS;
    vec3 normal;
} RESurfaceDataOut;

void main()
{
    RESurfaceDataOut.normal = mat3(transpose(inverse(modelMatrix))) * v_Normal;
    gl_Position = u_projection * u_view * modelMatrix * vec4(v_Position,1.0);
}