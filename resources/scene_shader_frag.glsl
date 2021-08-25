#version 430 core

struct lightingData
{
	vec4 ambientLight;
	vec4 mainLightDirection;
	vec4 mainLightColor;
};





vec3 re_get_ambient_color(lightingData ld)
{
	return ld.ambientLight.xyz * ld.ambientLight.w;
}


in RESurfaceData
{
	vec4 surfaceColor;
	vec2 uv;
	vec3 normalWS;

	vec2 viewPortSize;
	lightingData surfaceLightingData;
} RESurfaceDataIn;

vec2 re_get_screenspace_uv()
{
	return gl_FragCoord.xy / RESurfaceDataIn.viewPortSize;


}


out vec4 FragColor;
uniform sampler2D albedo;
void main()
{
	vec3 ambientColor = re_get_ambient_color(RESurfaceDataIn.surfaceLightingData);
	FragColor = RESurfaceDataIn.surfaceColor * vec4(ambientColor,1.0);

}