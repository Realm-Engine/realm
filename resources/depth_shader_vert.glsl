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


vec4 re_world_to_clipspace(vec3 ws)
{
	return  _vp * vec4( ws,1.0);
}

out float Color;


void main() {
		gl_Position =  re_world_to_clipspace(_position);
		Color = gl_Position.z / _camera.far_plane;
}