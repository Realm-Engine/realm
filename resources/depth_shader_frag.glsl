#version 430 core
#glsl_begin

in float SurfaceColor;

out float fragment_color;

void main()
{
	fragment_color =  SurfaceColor;

}

#glsl_end