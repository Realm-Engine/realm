#version 430 core
layout(location = 0) in vec3 _position;
layout(location = 1) in vec3 _normal;
layout (location = 2) in vec2 _texture_uv;

struct camera
{
	float near_plane;
	float far_plane;
	vec2 screen_size;
};


struct lightingData
{
	vec4 ambientLight;
	vec4 mainLightDirection;
	vec4 mainLightColor;
};



layout(std140,binding = 0) uniform _reGlobalData {
	mat4 _vp;
	camera _camera;
	lightingData _lightingData;
};

layout(packed, binding = 1) uniform _reUserData{
	vec4 color;

};



vec4 re_world_to_clipspace(vec3 ws)
{
	return  _vp * vec4( ws,1.0);
}

out RESurfaceData
{
	vec4 surfaceColor;
	vec2 uv;
	vec3 normalWS;
	vec2 viewPortSize;
	lightingData surfaceLightingData;
}RESurfaceDataOut;



void main() {
		gl_Position = re_world_to_clipspace(_position);
		RESurfaceDataOut.viewPortSize = _camera.screen_size;
		RESurfaceDataOut.surfaceColor = color;
		RESurfaceDataOut.uv = _texture_uv;
		RESurfaceDataOut.surfaceLightingData = _lightingData;
		RESurfaceDataOut.normalWS = _normal;
}

