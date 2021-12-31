#version 460 core
layout(location = 0) in vec3 v_Position;
layout(location = 1) in vec2 v_TexCoord;
layout(location =2) in vec3 v_Normal;
layout(location =3) in vec3 v_Tangent;

out vec2 texCoord;

struct ObjectData
{
    vec4 screenTexture;
};

void main()
{
    texCoord = v_TexCoord;
    glPosition = vec4(v_Position,1.0);
}