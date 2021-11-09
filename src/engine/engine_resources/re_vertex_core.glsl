
struct camera
{
	float near_plane;
	float far_plane;
	vec2 screen_size;
	vec4 position;
};

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



layout(std140, binding = 0) uniform _reGlobalData{
	mat4 _vp;
	camera _camera;
	lightingData _lightingData;
};

layout(packed, binding = 1) uniform _reUserData{
	vec4 color;

};



vec4 re_world_to_clipspace(vec3 ws)
{
	return  _vp * vec4(ws, 1.0);
}

mat3 calculate_TBN(vec3 normal, vec3 tangent)
{
	vec3 bitangent = cross(normal, tangent);
	return mat3(tangent, bitangent, normal);
}

out RESurfaceData
{
	vec4 surfaceColor;
	vec2 uv;
	vec3 normalWS;
	mat3 TBN;
	vec2 viewPortSize;
	vec3 posWS;
	vec4 posCS;
}RESurfaceDataOut;