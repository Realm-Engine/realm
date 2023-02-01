#version 460 core

layout (location = 0) out vec4 FragColor;
struct Material
{
    vec4 baseColor;
    vec4 diffuse;
};

layout(std430, binding = 0) buffer DrawContext
{
    mat4 u_view;
    mat4 u_projection;
    vec4 lightDirection;
};

layout(std140,binding = 1) uniform PerObjectData
{
    Material material;
    mat4 modelMatrix;
};



in RESurfaceData
{
    vec3 posWS;
    vec3 normal;
} RESurfaceDataIn;

void main()
{
    vec4 N = vec4(RESurfaceDataIn.normal,0.0);
    vec4 L = N - normalize(lightDirection);
    float d = max(dot(-lightDirection,N),0.0);
    float diffuse = 0;
    if(d > 0.9)
    {
        diffuse = 1.0;
    }
    else if(d > 0.7)
    {
        diffuse = 0.7;
    }
    else if(d > 0.5)
    {
        diffuse = 0.5;
    }
    else
    {
        diffuse = 0.3;
    }


    FragColor = material.baseColor * diffuse;

}