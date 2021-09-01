#version 430 core

struct pointLights
{	
	vec4 positions[4];
	vec4 colors[4];
	vec2 numLights;
};

struct lightingData
{
	vec4 ambientLight;
	vec4 mainLightDirection;
	vec4 mainLightColor;
	pointLights pointLightData;
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
	vec3 posWS;
	vec4 posCS;
}RESurfaceDataIn;


struct FragmentInputData
{
	vec4 surfaceColor;
	vec3 normalWS;
	lightingData surfaceLightingData;
	vec3 posWS;
	vec2 uv;

};

vec2 re_get_screenspace_uv()
{
	return gl_FragCoord.xy / RESurfaceDataIn.viewPortSize;


}



out vec4 FragColor;
layout(location = 0) uniform  sampler2D diffuseMap;
layout(location = 1) uniform  sampler2D normalMap;

vec3 re_calc_normalTS(vec2 uv)
{
	vec3 rgb_normal = texture(normalMap,uv).rgb;
	return rgb_normal;

}

vec3 re_calc_mainlight_color(lightingData lighting,vec3 normal)
{
	vec3 lightDirection = normalize(-lighting.mainLightDirection.xyz);
	float diffAmount = max(dot(normal,lightDirection),0.0);
	vec3 lightColor = lighting.mainLightColor.xyz * lighting.mainLightColor.w;

	return lightColor * diffAmount;
}

vec3 re_calc_pointlights_color(lightingData lighting,vec3 normal, vec3 fragPos)
{
	vec3 result = vec3(0);
	for(int i = 0; i < lighting.pointLightData.numLights.x;i++)
	{
		vec3 pos = lighting.pointLightData.positions[i].xyz;
		vec3 color = lighting.pointLightData.colors[i].xyz;
		vec3 direction = normalize(pos - fragPos);
		float diff = max(dot(normal,direction),0.0);
		vec3 diffuse = diff * color;
		result = result + diffuse;
	}
	return result;
}

vec4 re_calculate_fragment(FragmentInputData fragIn)
{
	lightingData lighting = fragIn.surfaceLightingData;

	vec3 normalSample = re_calc_normalTS(fragIn.uv);
	vec3 normal = normalize(normalSample * 2.0 - 1.0);
	vec3 lightColor = re_calc_mainlight_color(lighting,normal);
	vec3 pointLightContrib = re_calc_pointlights_color(lighting,normal,fragIn.posWS);
	vec3 ambientColor = re_get_ambient_color(fragIn.surfaceLightingData);
	vec4 diffuseSample = texture(diffuseMap,fragIn.uv);	
	vec3 baseColor = diffuseSample.rgb * fragIn.surfaceColor.rgb;

	vec3 lightContrib = lightColor + ambientColor + pointLightContrib;

	vec3 fragColor = baseColor *lightContrib;

	return vec4 (fragColor,diffuseSample.a);

}

void main()
{
	FragmentInputData fragIn;
	fragIn.surfaceColor = RESurfaceDataIn.surfaceColor;
	fragIn.normalWS = RESurfaceDataIn.normalWS;
	fragIn.surfaceLightingData = RESurfaceDataIn.surfaceLightingData;
	fragIn.posWS = RESurfaceDataIn.posWS;
	fragIn.uv = RESurfaceDataIn.uv;
	vec4 fragment = re_calculate_fragment(fragIn);

	FragColor = fragment;

}