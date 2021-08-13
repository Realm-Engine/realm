#include <stdio.h>
#include "engine/realm_engine.h"

#include "resource.c"
re_shader_program_t shader;
re_vertex_buffer_t* vertex_buffer;
re_index_buffer_t* index_buffer;
re_gfx_pipeline_t pipeline;
re_context_t* context;
re_mesh_t square_mesh;
re_transform_t square_transform;

re_camera_t* camera;
re_user_data_layout_t* layout;
re_texture_t* brick_texture;
void on_start(re_context_t* ctx);
void on_update(re_context_t* ctx);
void on_window_resize(re_context_t* ctx, int32_t width, int32_t height);
void on_key_action(re_context_t* ctx, re_key_action_t action, int32_t key);
void on_mouse_action(re_context_t* ctx, re_mouse_button_action_t action, int32_t button);
void on_mouse_pos(re_context_t* ctx, float x, float y, float last_x, float last_y);

int main(int argc, char** argv)
{
	printf("Hello, World!");
	square_transform = new_transform;
	square_transform.position = new_vec3(0, 0, 0.0f);
	square_transform.rotation = new_vec4(0.0f, 0.0f, 0, 1.0f);
	layout = (re_user_data_layout_t*)malloc(sizeof(re_user_data_layout_t));
	

	context = re_init((re_app_desc_t) {
		.height = 720,
			.width = 1280,
			.title = "Realm",

	});
	int width = 0;
	int height = 0;
	re_context_size(context, &width, &height);
	camera = re_create_camera(PERSPECTIVE, (re_view_desc_t) {
		.size = new_vec2(width, height),
			.fov_angle = 45,
			.near_plane = 0.1f,
			.far_plane = 100.0f
	});
	camera->camera_transform.rotation = new_vec4(0.1f, 0.0f, 0.0f, 1);
	camera->camera_transform.position = new_vec3(0.0f,0.0f, 0.0f);
	re_init_gfx();

	re_set_event_handler(context, (re_event_handler_desc_t) {
		.on_start = &on_start,
			.on_update = &on_update,
			.on_window_resize = &on_window_resize,
			.on_user_key_action = &on_key_action

	});


	brick_texture = (re_texture_t*)malloc(sizeof(re_texture_t));
	if (re_read_image("./resources/wall.jpg", brick_texture,(re_texture_desc_t){.filter = LINEAR,.wrap = CLAMP_TO_EDGE,.type = TEXTURE2D}) == RE_OK)
	{
		re_gen_texture(brick_texture);
	}
	re_start(context);

	return 1;


}

void on_start(re_context_t* ctx)
{
	
	printf("Start");
	square_mesh.positions = NULL;
	square_mesh.positions = (vec3*)malloc(sizeof(vec3) * 4);
	square_mesh.texcoords = (vec2*)malloc(sizeof(vec2) * 4);
	int i;
	for (i = 0; i < 4; i++)
	{
		memcpy(&square_mesh.positions[i], square_model[i], sizeof(vec3));
		memcpy(&square_mesh.texcoords[i], square_uv[i], sizeof(vec2));
	}



	square_mesh.triangles = (uint32_t*)malloc(sizeof(uint32_t) * 6);
	memcpy(square_mesh.triangles, square_triangles, sizeof(uint32_t) * 6);
	square_mesh.mesh_size = 4;

	char fragment[256];
	memset(fragment, 0, sizeof(fragment));
	re_read_text("./resources/re_fragment.glsl", fragment);
	char vertex[512];
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
	.num_attribs = 2,
	.attributes = {
			{.index = 0,.type = FLOAT3,.offset = 0,.attribute_slot = RE_POSITION_ATTRIBUTE},
			{.index = 1, .type = FLOAT2, .offset = 12,.attribute_slot = RE_TEXCOORD_ATTRIBUTE}
		},
	.program = shader,

	};
	re_init_gfx_pipeline(&pipeline);
	re_set_bg_color(153.0f, 46.0f, 137.0f, 255.0f, 1);
	vec3_to_string(re_compute_camera_front(camera));
	
	re_query_userdata_layout(&pipeline, layout);





}
void on_update(re_context_t* ctx)
{
	re_clear_color();


	mat4x4 vp= re_compute_view_projection(camera);
	
	
	re_update_vp(&pipeline,&vp );
	re_pipeline_start_draw(&pipeline);
	{
		re_set_texture(&pipeline, "albedo", brick_texture);
		re_set_userdata_vector(layout, "color", new_vec4(0.5f, 1.0, 1.0, 1.0));
		re_upload_mesh_data(&square_mesh, &square_transform,&pipeline);
		//re_upload_index_data(square_triangles, 6);
		re_draw_triangles(6);
	}
	re_pipeline_end_draw(&pipeline);


}

void on_window_resize(re_context_t* ctx,int32_t width, int32_t height)
{
	camera->size.x = (float)width;
	camera->size.y = (float)height;

}

void on_key_action(re_context_t* ctx, re_key_action_t action, int32_t key)
{
	vec3 move_vector = vec3_zero;
	switch (action)
	{
	case KEY_DOWN:
		switch (key)
		{
		case GLFW_KEY_W:
			printf("moving forward");
			move_vector = vec3_scalar_mul( re_compute_camera_front(camera),-0.1f);
			break;
		case GLFW_KEY_D:
			move_vector = vec3_scalar_mul(re_compute_camera_right(camera), 0.1f);
			break;
		case GLFW_KEY_S:
			printf("moving forward");
			move_vector = vec3_scalar_mul(re_compute_camera_front(camera), 0.1f);
			break;
		case GLFW_KEY_A:
			move_vector = vec3_scalar_mul(re_compute_camera_right(camera), -0.1f);
			break;
		
		default:
			break;
		}
	default:
		break;
	}
	camera->camera_transform.position =  vec3_add(camera->camera_transform.position, move_vector);
}

void on_mouse_action(re_context_t* ctx, re_mouse_button_action_t action, int32_t button)
{
}

void on_mouse_pos(re_context_t* ctx, float x, float y, float last_x, float last_y)
{
}

