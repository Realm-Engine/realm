#include <stdio.h>
#include "engine/realm_engine.h"
#include "engine/gfx_ogl.h"
#include "resource.c"
re_shader_program_t shader;
re_vertex_buffer_t* vertex_buffer;
re_index_buffer_t* index_buffer;
re_gfx_pipeline_t pipeline;
re_context_t* context;
re_mesh_t square_mesh;
void on_start();
void on_update();

int main(int argc, char** argv)
{
	printf("Hello, World!");


	context = re_init((re_app_desc_t) {
		.height = 720,
			.width = 1280,
			.title = "Realm",

	});
	re_init_gfx();

	re_set_event_handler(context, (re_event_handler_desc_t) {
		.on_start = &on_start,
			.on_update = &on_update

	});



	re_start(context);

	return 1;


}

void on_start(re_context_t* ctx)
{
	printf("Start");
	square_mesh.positions = NULL;
	square_mesh.positions = (vec3_t*)malloc(sizeof(vec3_t) * 4);


	for (int i = 0; i < 4; i++)
	{
		memcpy(&square_mesh.positions[i], square_model[i], sizeof(vec3_t));
	}

	square_mesh.triangles = (uint32_t*)malloc(sizeof(uint32_t) * 6);
	memcpy(&square_mesh.triangles, square_triangles, sizeof(uint32_t) * 6);
	square_mesh.mesh_size = 4;

	char fragment[256];
	memset(fragment, 0, sizeof(fragment));
	re_read_text("./resources/re_fragment.glsl", fragment);
	char vertex[256];
	memset(vertex, 0, sizeof(vertex));
	re_read_text("./resources/re_vertex.glsl", vertex);
	
	shader = (re_shader_program_t){
			.name = "Default",
			.source = {
				{.name = "Vertex Shader",.source = vertex,.type = RE_VERTEX_SHADER},
				{.name = "Fragment Shader",.source = fragment, .type = RE_FRAGMENT_SHADER}
			},

	};
	re_compile_shader(&shader.source[0]);
	re_compile_shader(&shader.source[1]);
	re_init_program(&shader);

	pipeline = (re_gfx_pipeline_t){
	.num_attribs = 1,
	.attributes = {
			{.index = 0,.type = FLOAT3,.offset = 0}
		},
	.program = shader,

	};
	re_init_gfx_pipeline(&pipeline);
	re_set_bg_color(153.0f, 46.0f, 137.0f, 255.0f, 1);
	



}
void on_update(re_context_t* ctx)
{
	re_clear_color();
	
	int width = 0;
	int height = 0;
	re_context_size(ctx, &width, &height);
	re_update_vp(&pipeline, re_perspective(90,width/height,0.1f,100.0f));
	re_pipeline_start_draw(&pipeline);
	{
		re_upload_vertex_data(square_mesh.positions, square_mesh.mesh_size);
		re_upload_index_data(square_triangles, 6);
		re_draw_triangles(6);
	}
	re_pipeline_end_draw(&pipeline);


}