#version 430 core
layout(location = 0) in vec3 _position;
out vec4 Color;

layout(std140,binding = 0) uniform _reGlobalData {
	mat4 _vp;
};

layout(packed, binding = 1) uniform _reUserData{
	vec4 color;
};

vec4 re_world_to_clipspace(vec3 ws)
{
	return  _vp * vec4( ws,1.0);
}

void main() {
		gl_Position =  re_world_to_clipspace(_position);
		Color = color;
}

