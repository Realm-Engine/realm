#version 430 core
#shader_type vertex
#target screen
#glsl_begin

out vec2 TextureCoords;

void main() {
		gl_Position =  vec4(_position.x,_position.y,0,1.0);
		TextureCoords = _texture_uv;
}
#glsl_end
