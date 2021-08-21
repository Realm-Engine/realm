#version 430 core
out vec4 FragColor;
in vec4 Color;
in vec2 AlbedoUV;

layout(binding = 0) uniform sampler2D albedo;


void main()
{
	FragColor =  Color;

}