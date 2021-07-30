#version 430 core
layout(location = 0) in vec3 _position;
out vec3 Color;

layout(std140,binding = 0) uniform _reGlobalData {
	mat4 vp;


};

void main() {
		gl_Position =  vp * vec4(_position.xyz,1.0) ;
		Color = vec3(1.0,1.0,1.0);
}

