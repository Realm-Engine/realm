#version 430 core
#shader_type fragment
#target screen
#glsl_start
out vec4 FragColor;
  
in vec2 TextureCoords;

layout(binding = 0) uniform sampler2D screenTexture;

void main()
{ 
    
    vec4 screenColor = texture(screenTexture, TextureCoords);
    FragColor = screenColor;
}
#glsl_end