#version 430 core
#shader_type fragment
#target scene

#glsl_begin
out vec4 FragColor;
layout(location = 0) uniform sampler2D diffuseMap;
layout(location = 1) uniform sampler2D normalMap;

void main()
{
	FragmentInputData fragIn;
	fragIn.surfaceColor = RESurfaceDataIn.surfaceColor;
	fragIn.normalWS = RESurfaceDataIn.normalWS;
	
	fragIn.posWS = RESurfaceDataIn.posWS;
	fragIn.uv = RESurfaceDataIn.uv;
	fragIn.normalSample = texture(normalMap, RESurfaceDataIn.uv).rgb;
	fragIn.diffuse = texture(diffuseMap, RESurfaceDataIn.uv);
	vec4 fragment = re_calculate_fragment(fragIn);
	FragColor = fragment;

}
#glsl_end