#version 430 core
layout(location = 0) in vec3 _position;
layout(location = 1) in vec3 _normal;
layout (location = 2) in vec2 _texture_uv;


out vec2 TextureCoords;

void main() {
		gl_Position =  vec4(_position.x,_position.y,0,1.0);
		TextureCoords = _texture_uv;
}

