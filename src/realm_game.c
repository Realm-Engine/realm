
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
			.on_user_key_action = &on_key_action,
			.on_user_mouse_move = &on_mouse_pos

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
		.num_attribs = 3,
			.attributes = {
					{.index = 0,.type = FLOAT3,.offset = 0,.attribute_slot = RE_POSITION_ATTRIBUTE},
					{.index = 1,.type = FLOAT3,.offset = 12,.attribute_slot = RE_NORMAL_ATTRIBUTE},
					{.index = 2, .type = FLOAT2, .offset = 24,.attribute_slot = RE_TEXCOORD_ATTRIBUTE},
				
		}
	});
	re_init_gfx_pipeline();


	re_set_bg_color(153.0f, 46.0f, 137.0f, 255.0f, 1);
	vec3_to_string(re_compute_camera_front(state.camera));
	
	scene_root = &actors[0];
	scene_root->mesh.mesh_size = 0;
	square_actor = &actors[1];
	init_actor(scene_root);
	init_actor(square_actor);
	re_fill_mesh(&square_actor->mesh, (vec3*)square_model, (vec3*)square_normal, (vec2*)square_uv, 4);
	re_set_mesh_triangles(&square_actor->mesh, square_triangles, 6);

	re_actor_add_child(scene_root, square_actor);
	re_set_material_vector(&square_actor->material_properties, "color", new_vec4(1, 1, 1, 1));
	re_update_ambient_light(new_vec3(0.5f, 1.0, 1.0), 1.0);


	//re_query_userdata_layout(&state.pipeline, layout);


}

void realm_update(re_context_t ctx)
{
	//re_clear_color();

	mat4x4 vp = re_compute_view_projection(state.camera);


	re_update_vp(vp);
	re_set_camera_data(state.camera);
	
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

			move_vector = vec3_scalar_mul(re_compute_camera_front(state.camera), -0.1f);
			break;
		case GLFW_KEY_D:
			move_vector = vec3_scalar_mul(re_compute_camera_right(state.camera), 0.1f);
			break;
		case GLFW_KEY_S:

			move_vector = vec3_scalar_mul(re_compute_camera_front(state.camera), 0.1f);
			break;
		case GLFW_KEY_A:
			move_vector = vec3_scalar_mul(re_compute_camera_right(state.camera), -0.1f);
			break;
		case GLFW_KEY_E:
			state.camera->camera_transform.rotation.y -= 0.01f;
			break;
		case GLFW_KEY_Q:
			state.camera->camera_transform.rotation.y += 0.01f;

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
	float xoffset = x - last_x;
	float yoffset = last_y - y;
	vec3 euler = quat_to_euler(state.camera->camera_transform.rotation);
	float pitch = euler.x;
	float yaw = euler.y;
	float roll = euler.z;
	xoffset *= 0.005f;
	yoffset *= 0.005f;

	yaw += xoffset;
	pitch += yoffset;
	if (pitch > 89.0f)
	{
		pitch = 89.0f;
	}
	if (pitch < -89.0f)
	{
		pitch = -89.0f;
	}
	vec3 dir;
	
	quaternion new_rotation = vec4_add(state.camera->camera_transform.rotation, new_vec4(xoffset, yoffset, 0, 0));
	
	//state.camera->camera_transform.rotation = new_rotation;



}