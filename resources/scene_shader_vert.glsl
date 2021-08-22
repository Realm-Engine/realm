#version 430 core
layout(location = 0) in vec3 _position;
layout (location = 1) in vec2 _texture_uv;


struct camera
{
	float near_plane;
	float far_plane;
	vec2 screen_size;
};

layout(std140,binding = 0) uniform _reGlobalData {
	mat4 _vp;
	camera _camera;
};

layout(packed, binding = 1) uniform _reUserData{
	vec4 color;

};



vec4 re_world_to_clipspace(vec3 ws)
{
	return  _vp * vec4( ws,1.0);
}

out vec4 Color;
out vec2 AlbedoUV;
out vec2 ViewPortSize;
void main() {
		gl_Position =  re_world_to_clipspace(_position);
		ViewPortSize = _camera.screen_size;
		Color = color;
		AlbedoUV = _texture_uv;
}

