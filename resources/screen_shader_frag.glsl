#version 430 core
out vec4 FragColor;
  
in vec2 TextureCoords;

layout(binding = 0) uniform sampler2D screenTexture;

void main()
{ 
    FragColor = texture(screenTexture, TextureCoords);
}