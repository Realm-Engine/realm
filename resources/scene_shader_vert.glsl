#version 430 core
#shader_type vertex
#target scene
#glsl_start 

void main() {
		RESurfaceDataOut.posCS = re_world_to_clipspace(_position);
		RESurfaceDataOut.posWS = _position;
		RESurfaceDataOut.viewPortSize = _camera.screen_size;
		RESurfaceDataOut.surfaceColor = color;
		RESurfaceDataOut.uv = _texture_uv;
		RESurfaceDataOut.normalWS = _normal;
		gl_Position = RESurfaceDataOut.posCS;

}
#glsl_end
