#version 430 core
#shader_type fragment
#target scene
#glsl_begin

in float SurfaceColor;

out float fragment_color;

void main()
{
	fragment_color =  SurfaceColor;

}

#glsl_end