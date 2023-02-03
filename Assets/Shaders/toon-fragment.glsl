#version 460 core

layout (location = 0) out vec4 FragColor;
struct Material
{
    vec4 baseColor;
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

uniform sampler2D diffuse;
uniform sampler2D normal;

in RESurfaceData
{
    vec3 posWS;
    vec3 normal;
    vec2 texCoord;
} RESurfaceDataIn;

void main()
{
    vec4 N = vec4(normalize(RESurfaceDataIn.normal),0.0);
    vec4 L = N - normalize(lightDirection);
    float d = max(dot(-lightDirection,N),0.0);
    float amount = 0;
    if(d > 0.9)
    {
        amount = 1.0;
    }
    else if(d > 0.7)
    {
        amount = 0.7;
    }
    else if(d > 0.5)
    {
        amount = 0.5;
    }
    else
    {
        amount = 0.3;
    }


    FragColor = texture(diffuse,RESurfaceDataIn.texCoord) * amount;

}