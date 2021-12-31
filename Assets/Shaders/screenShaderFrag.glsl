#version 460 core

in vec2 texCoord;
uniform sampler2D screenTexture;

void main()
{
    FragColor = vec4(texture(texCoord,mainTexture),1.0);

}