
#define REALM_ENGINE_IMPL
#include "realm_game.h"

void realm_main()
{
	re_init((re_app_desc_t) {
		.height = 720,
			.width = 1280,
			.title = "Realm",
	});
	re_init_gfx();
	re_set_event_handler((re_event_handler_desc_t) {
		.on_start = &realm_start,
			.on_update = &realm_update,
			.on_window_resize = &on_window_resize,
			.on_user_key_action = &on_key_action

	});

	re_start();
}

void realm_start(re_context_t ctx)
{

	printf("Start");
	int width = 0;
	int height = 0;
	re_context_size(&width, &height);

	state.camera = re_create_camera(PERSPECTIVE, (re_view_desc_t) {
		.size = new_vec2(width, height),
			.fov_angle = 45,
			.near_plane = 0.1f,
			.far_plane = 100.0f
	});


	
	re_set_pipeline_desc(&(re_gfx_pipeline_desc_t) {
		.num_attribs = 2,
			.attributes = {
					{.index = 0,.type = FLOAT3,.offset = 0,.attribute_slot = RE_POSITION_ATTRIBUTE},
					{.index = 1, .type = FLOAT2, .offset = 12,.attribute_slot = RE_TEXCOORD_ATTRIBUTE}
		}
	});
	re_init_gfx_pipeline();


	re_set_bg_color(153.0f, 46.0f, 137.0f, 255.0f, 1);
	vec3_to_string(re_compute_camera_front(state.camera));
	scene_root = &actors[0];
	square_actor = &actors[1];
	other_actor = &actors[2];
	init_actor(square_actor);
	init_actor(scene_root);
	init_actor(other_actor);
	square_actor->mesh.positions = (vec3*)malloc(sizeof(square_model));
	square_actor->mesh.texcoords = (vec2*)malloc(sizeof(square_uv));
	square_actor->mesh.triangles = (uint32_t*)malloc(sizeof(square_triangles));
	square_actor->mesh.mesh_size = 4;

	memcpy(square_actor->mesh.positions, square_model, sizeof(square_model));
	memcpy(square_actor->mesh.texcoords, square_uv, sizeof(square_uv));
	memcpy(square_actor->mesh.triangles, square_triangles, sizeof(square_triangles));
	other_actor->transform.position = new_vec3(1, 0, -3);
	other_actor->mesh.positions = (vec3*)malloc(sizeof(square_model));
	other_actor->mesh.texcoords = (vec2*)malloc(sizeof(square_uv));
	other_actor->mesh.triangles = (uint32_t*)malloc(sizeof(square_triangles));
	other_actor->mesh.mesh_size = 4;
	memcpy(other_actor->mesh.positions, square_model, sizeof(square_model));
	memcpy(other_actor->mesh.texcoords, square_uv, sizeof(square_uv));
	memcpy(other_actor->mesh.triangles, square_triangles, sizeof(square_triangles));
	other_actor->transform = new_transform;
	other_actor->transform.scale = new_vec3(5, 5, 1);
	square_actor->transform = new_transform;
	square_actor->transform.scale = new_vec3(10, 10,1);
	square_actor->transform.position = new_vec3(0, 0, -2);
	square_actor = re_actor_add_child(scene_root, *square_actor);
	other_actor = re_actor_add_child(scene_root, *other_actor);
	other_actor->transform.position = new_vec3(2, 0, -1);
	
	//re_query_userdata_layout(&state.pipeline, layout);


}

void realm_update(re_context_t ctx)
{
	//re_clear_color();


	mat4x4 vp = re_compute_view_projection(state.camera);


	re_update_vp(vp);
	re_pipeline_start_draw();
	{
		//re_upload_mesh_data(&square_actor->mesh, &square_actor->transform);
		re_render_scene(scene_root);
	}
	re_pipeline_end_draw();

}

void on_window_resize(re_context_t* ctx, int32_t width, int32_t height)
{
	state.camera->size.x = (float)width;
	state.camera->size.y = (float)height;

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
			move_vector = vec3_scalar_mul(re_compute_camera_front(state.camera), -0.1f);
			break;
		case GLFW_KEY_D:
			move_vector = vec3_scalar_mul(re_compute_camera_right(state.camera), 0.1f);
			break;
		case GLFW_KEY_S:
			printf("moving forward");
			move_vector = vec3_scalar_mul(re_compute_camera_front(state.camera), 0.1f);
			break;
		case GLFW_KEY_A:
			move_vector = vec3_scalar_mul(re_compute_camera_right(state.camera), -0.1f);
			break;

		default:
			break;
		}
	default:
		break;
	}
	state.camera->camera_transform.position = vec3_add(state.camera->camera_transform.position, move_vector);
}

void on_mouse_action(re_context_t* ctx, re_mouse_button_action_t action, int32_t button)
{
}

void on_mouse_pos(re_context_t* ctx, float x, float y, float last_x, float last_y)
{
}