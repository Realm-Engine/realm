#version 430 core
#shader_type vertex
#target scene
#glsl_start
out float SurfaceColor;
void main() {
		gl_Position =  re_world_to_clipspace(_position);
		SurfaceColor = gl_Position.z / _camera.far_plane;
}
#glsl_end