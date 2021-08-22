#version 430 core
out vec4 FragColor;
in vec4 Color;
in vec2 AlbedoUV;
in vec2 ViewPortSize;

uniform sampler2D albedo;


vec2 re_get_screenspace_uv()
{
	return gl_FragCoord.xy / ViewPortSize;


}

void main()
{
	FragColor =  texture(albedo,AlbedoUV);

}