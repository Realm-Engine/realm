#shader shared
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
#shader vertex

layout(location = 0) in vec3 v_Position;
layout(location = 1) in vec3 v_Normal;
layout(location = 2) in vec2 v_TexCoord;
layout(location = 3) in vec3 v_Tangent;

out gl_PerVertex
{
	vec4 gl_Position;
};
out RESurfaceData
{
    vec3 posWS;
    vec3 normal;
    vec2 texCoord;
} RESurfaceDataOut;

void main()
{
    RESurfaceDataOut.texCoord = v_TexCoord;
    RESurfaceDataOut.normal = mat3(transpose(inverse(modelMatrix))) * v_Normal;
    gl_Position = u_projection * u_view * modelMatrix * vec4(v_Position,1.0);
}

#shader fragment

layout (location = 0) out vec4 FragColor;
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