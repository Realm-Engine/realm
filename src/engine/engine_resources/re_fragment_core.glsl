
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

struct camera
{
	float near_plane;
	float far_plane;
	vec2 screen_size;
	vec4 position;
};

layout(std140, binding = 0) uniform _reGlobalData{
	mat4 _vp;
	camera _camera;
	lightingData _lightingData;
};

struct FragmentInputData
{
	vec4 surfaceColor;
	vec3 normalWS;
	vec4 diffuse;
	mat3 TBN;
	vec3 normalSample;
	lightingData surfaceLightingData;
	vec3 posWS;
	vec2 uv;
	

};

in RESurfaceData
{
	vec4 surfaceColor;
	vec2 uv;
	vec3 normalWS;
	mat3 TBN;
	vec2 viewPortSize;
	vec3 posWS;
	vec4 posCS;
}RESurfaceDataIn;


vec3 re_get_ambient_color(lightingData ld)
{
	return ld.ambientLight.xyz * ld.ambientLight.w;
}

vec2 re_get_screenspace_uv()
{
	return gl_FragCoord.xy / RESurfaceDataIn.viewPortSize;


}

vec3 re_calc_mainlight_color(lightingData lighting, vec3 normal)
{
	vec3 lightDirection = normalize(-lighting.mainLightDirection.xyz );
	float diffAmount = max(dot(normal, lightDirection), 0.0);
	vec3 lightColor = lighting.mainLightColor.xyz * lighting.mainLightColor.w;

	return lightColor * diffAmount;
}

vec3 re_calc_pointlights_color(lightingData lighting, vec3 normal, vec3 fragPos)
{
	vec3 result = vec3(0);
	for (int i = 0; i < lighting.pointLightData.numLights.x; i++)
	{

		 
		
		vec3 color = lighting.pointLightData.colors[i].xyz;
		vec3 direction =  normalize(lighting.pointLightData.positions[i].xyz - fragPos);
		float diff = max(dot(normal, direction), 0.0);
		vec3 diffuse = diff * color;
		float specStrength = 0.5;
		vec3 viewDir = normalize(_camera.position.xyz - fragPos);
		vec3 reflectDir =  reflect(-direction, normal);

		float specularPower = pow(max(dot(viewDir, reflectDir), 0.0), 32);
		float specular = specStrength * specularPower;

		result = result + (diffuse * specular);
	}
	return result;
}

vec4 re_calculate_fragment(FragmentInputData fragIn)
{
	lightingData lighting = _lightingData;

	vec3 normalSample = fragIn.normalSample;
	vec3 normal = normalSample * 2.0 - 1.0;
	normal = normalize(fragIn.TBN * normal);
	vec3 lightColor = re_calc_mainlight_color(lighting, normal);
	vec3 pointLightContrib = re_calc_pointlights_color(lighting, normal, fragIn.posWS);
	vec3 ambientColor = re_get_ambient_color(fragIn.surfaceLightingData);

	vec3 baseColor = fragIn.diffuse.rgb * fragIn.surfaceColor.rgb;

	vec3 lightContrib = lightColor + ambientColor + pointLightContrib;

	vec3 fragColor = baseColor * lightContrib;

	return vec4(fragColor, fragIn.diffuse.a);

}