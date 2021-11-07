
#define REALM_ENGINE_IMPL
#define REALM_ENGINE_DEBUG
#include "realm_game.h"

re_app_desc_t realm_main(int argc, char** argv)
{

	return( (re_app_desc_t) {
		.height = 720,
			.width = 1280,
			.title = "Realm",
			.evh = (&(re_event_handler_desc_t) {
			.on_start = &realm_start,
				.on_update = &realm_update,
				.on_window_resize = &on_window_resize,
				.on_user_key_action = &on_key_action,
				.on_user_mouse_move = &on_mouse_pos,
				.on_user_mouse_action = &on_mouse_action
		})

	});

	
}

void realm_start(re_context_t ctx)
{

	int width = 0;
	int height = 0;
	re_context_size(&width, &height);
	wall_texture = (re_texture_t*)malloc(sizeof(re_texture_t));
	wall_normal_texture = (re_texture_t*)malloc(sizeof(re_texture_t));
	re_read_image("./resources/brickwall.jpg", wall_texture, (re_texture_desc_t) { .filter = LINEAR, .wrap = REPEAT, .type = TEXTURE2D, .format = RGB });
	re_gen_texture(wall_texture);
	re_read_image("./resources/brickwall_normal.jpg", wall_normal_texture, (re_texture_desc_t) { .filter = LINEAR, .wrap = CLAMP_TO_EDGE, .type = TEXTURE2D, .format = RGB });
	re_gen_texture(wall_normal_texture);
	re_free_texture_data(wall_texture);
	re_free_texture_data(wall_normal_texture);
	state.camera = re_create_camera(RE_PERSPECTIVE, (re_view_desc_t) {
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
	light.color = new_vec3(1.0, 0.0, 0.3);
	light.instensity = 1.0f;
	light.transform.position = new_vec3(-1.0, -0.5f, 0);
	init_actor(scene_root);
	init_actor(square_actor);
	//re_parse_obj_geo("./resources/Plane.obj",&square_actor->mesh);
	tinyobj_attrib_t shape_attrib;
	tinyobj_shape_t* shapes = NULL;
	size_t num_shapes;
	tinyobj_material_t* materials = NULL;
	size_t num_materials;
	//tinyobj_parse_obj(&shape_attrib, &shapes, &num_shapes, &materials, &num_materials, "./resources/Plane.obj",read_obj_file, NULL, TINYOBJ_FLAG_TRIANGULATE);
	//obj_to_mesh(&shape_attrib, shapes, &square_actor->mesh);

	//re_set_mesh_triangles(&square_actor->mesh, square_triangles, 6);
	//re_fill_mesh(&square_actor->mesh, (vec3*)square_model, (vec3*)square_normal, (vec2*)square_uv, 4);
	generate_cube(2, &square_actor->mesh);
	//square_actor->transform.rotation = euler_to_quat(new_vec3(deg_to_rad(90), 0, 0));

	square_actor->transform.position = new_vec3(0, -0.0f, -1.0f);
	re_actor_add_child(scene_root, square_actor);
	re_set_material_vector(&square_actor->material_properties, "color", new_vec4(1, 1, 1, 1));
	re_update_ambient_light(vec3_scalar_mul(new_vec3(43, 85, 112), (float)1 / 255), 0.0f);
	re_add_pointlight(&light);
	state.mainlight.color = new_vec3(255, 255, 255);
	state.mainlight.color = vec3_scalar_mul(state.mainlight.color, (float)1 / 255);
	state.mainlight.intensity = 1.0f;
	state.mainlight.transform = new_transform;

	//state.mainlight.transform.rotation = euler_to_quat(new_vec3(deg_to_rad(90), 20, 0));
	re_set_material_texture(&square_actor->material_textures, "diffuseMap", *wall_texture);
	re_set_material_texture(&square_actor->material_textures, "normalMap", *wall_normal_texture);
	//re_query_userdata_layout(&state.pipeline, layout);


}

void obj_to_mesh(tinyobj_attrib_t* attributes, tinyobj_shape_t* shapes, re_mesh_t* mesh)
{
	vector(vec3) vertices = new_vector(vec3, attributes->num_faces);
	vector(vec3) normals = new_vector(vec3, attributes->num_normals);
	vector(vec2) texcoords = new_vector(vec2, attributes->num_faces);
	vector(uint32_t) faces = new_vector(uint32_t, attributes->num_faces);
	vec3* mesh_vertices = (vec3*)malloc(sizeof(vec3) * attributes->num_vertices);
	vec3* mesh_normals = (vec3*)malloc(sizeof(vec3) * attributes->num_vertices);
	vec3* mesh_texcoords = (vec3*)malloc(sizeof(vec3) * attributes->num_vertices);
	int i, j;
	/*for (i = 0; i < attributes->num_vertices; i++)
	{
		vec3 vertex = new_vec3(attributes->vertices[i], attributes->vertices[i + 1], attributes->vertices[i + 2]);

		vector_insert(vec3, &vertices,vertex );


	}
	for (i = 0; i < attributes->num_normals; i++)
	{
		vec3 normal = new_vec3(attributes->normals[i], attributes->normals[i + 1], attributes->normals[i + 2]);
		vector_insert(vec3, &normals, normal);
	}

	for (i = 0; i < attributes->num_texcoords; i++)
	{
		vec2 texcoord = new_vec2(attributes->texcoords[i], attributes->texcoords[i + 1]);
		vector_insert(vec2, &texcoords, texcoord);
	}*/

	for (i = 0; i < attributes->num_faces; i++)
	{
		tinyobj_vertex_index_t idx = attributes->faces[i];

		vertices.elements[idx.v_idx] = new_vec3(attributes->vertices[idx.v_idx], attributes->vertices[idx.v_idx + 1], attributes->vertices[idx.v_idx + 2]);
		normals.elements[idx.vn_idx] = new_vec3(attributes->normals[idx.vn_idx], attributes->normals[idx.vn_idx + 1], attributes->normals[idx.vn_idx + 2]);
		texcoords.elements[idx.vt_idx] = new_vec2(attributes->texcoords[idx.vt_idx], attributes->texcoords[idx.vt_idx + 1]);
		vertices.count++;
		normals.count++;
		texcoords.count++;
		vector_append(uint32_t, &faces, i);
	}



	re_fill_mesh(mesh, vertices.elements, normals.elements, texcoords.elements, attributes->num_faces);


	re_set_mesh_triangles(mesh, faces.elements, attributes->num_faces);



}

void generate_cube(uint32_t resolution, re_mesh_t* mesh)
{
	int i;
	vec3 directions[6] =
	{
		vec3_up,
		vec3_down,
		vec3_forward,
		vec3_back,
		vec3_right,
		vec3_left


	};
	vector(vec3) positions = new_vector(vec3, (resolution * resolution) * 6);
	vector(vec3) normals = new_vector(vec3, (resolution * resolution) * 6);
	vector(vec2) uv = new_vector(vec2, (resolution * resolution) * 6);
	vector(uint32_t) indices = new_vector(uint32_t, ((resolution * resolution) * 6) * 6);
	for (i = 0; i < 6; i++)
	{
		re_mesh_t tmp;
		generate_plane(directions[i], resolution, &tmp, i * (resolution - 1 * resolution - 1));
		vector_append_range(vec3, &positions, tmp.positions.elements, tmp.positions.count);
		vector_append_range(vec3, &normals, tmp.normals.elements, tmp.normals.count);
		vector_append_range(vec2, &uv, tmp.texcoords.elements, tmp.texcoords.count);
		vector_append_range(uint32_t, &indices, tmp.triangles.elements, tmp.triangles.count);

	}
	re_fill_mesh(mesh, positions.elements, normals.elements, uv.elements, positions.count);
	re_set_mesh_triangles(mesh, indices.elements, indices.count);
	re_print(mesh);
}

void generate_plane(vec3 normal, uint32_t resolution, re_mesh_t* mesh, uint32_t index_offset)
{
	vec3 axisA = new_vec3(normal.y, normal.z, normal.x);
	vec3 axisB = vec3_cross(normal, axisA);

	vector(vec3) vertices = new_vector(vec3, resolution * resolution);
	vector(uint32_t) triangles = new_vector(uint32_t, (resolution - 1) * (resolution - 1) * 6);
	vector(vec3) normals = new_vector(vec3, resolution * resolution);
	vector(vec2) uv = new_vector(vec2, resolution * resolution);
	int triIndex = 0;

	int y, x;

	for (y = 0; y < resolution; y++)
	{
		for (x = 0; x < resolution; x++)
		{
			int vidx = x + y * resolution;
			vec2 t = new_vec2(x / (resolution - 1.f), y / (resolution - 1.f));

			vec3 point = vec3_add(normal, vec3_scalar_mul(axisA, (2 * t.x - 1)));

			point = vec3_add(point, vec3_scalar_mul(axisB, 2 * t.y - 1));

			vector_insert(vec3, &vertices, vidx, point);
			vector_insert(vec3, &normals, vidx, normal);
			vector_insert(vec2, &uv, vidx, t);
			vidx += index_offset;
			if (x != resolution - 1 && y != resolution - 1)
			{
				vector_insert(uint32_t, &triangles, triIndex + 0, vidx);
				vector_insert(uint32_t, &triangles, triIndex + 1, vidx + resolution + 1);
				vector_insert(uint32_t, &triangles, triIndex + 2, vidx + resolution);
				vector_insert(uint32_t, &triangles, triIndex + 3, vidx);
				vector_insert(uint32_t, &triangles, triIndex + 5, vidx + 1);
				vector_insert(uint32_t, &triangles, triIndex + 4, vidx + resolution + 1);



			}

		}
	}

	re_fill_mesh(mesh, vertices.elements, normals.elements, uv.elements, resolution * resolution);
	re_set_mesh_triangles(mesh, triangles.elements, triangles.count);


}

re_mesh_t* generate_sphere(uint32_t resolution)
{

}



void realm_update(re_context_t ctx)
{
	//re_clear_color();

	mat4x4 vp = re_compute_view_projection(state.camera);

	float t = glfwGetTime();
	float sint = re_sin(t);
	//state.mainlight.transform.rotation.y += sint * 0.01;

	re_update_vp(vp);
	re_set_camera_data(state.camera);
	re_update_main_light(&state.mainlight);
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
	vec3 euler = quat_to_euler(state.camera->camera_transform.rotation);
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
		case GLFW_KEY_RIGHT:
			euler.y += 0.05f;
			break;
		case GLFW_KEY_LEFT:
			euler.y -= 0.05f;
			break;
		case GLFW_KEY_UP:
			euler.x -= 0.05f;
			break;
		case GLFW_KEY_DOWN:
			euler.x += 0.05f;
			break;
		default:
			break;
		}
	default:
		break;
	}
	state.camera->camera_transform.rotation = euler_to_quat(euler);
	state.camera->camera_transform.position = vec3_add(state.camera->camera_transform.position, move_vector);
}

void on_mouse_action(re_context_t* ctx, re_mouse_button_action_t action, int32_t button)
{
	if (button == GLFW_MOUSE_BUTTON_RIGHT && (action == GLFW_PRESS))
	{
		state.mainlight.transform.rotation.y += 0.1f;
	}
	if (button == GLFW_MOUSE_BUTTON_LEFT && (action == GLFW_PRESS))
	{
		state.mainlight.transform.rotation.y -= 0.1f;
	}


}

void on_mouse_pos(re_context_t* ctx, float x, float y, float last_x, float last_y)
{
	float xoffset = x - last_x;
	float yoffset = last_y - y;
	vec3 euler = quat_to_euler(state.camera->camera_transform.rotation);

	xoffset *= 0.01f;
	yoffset *= 0.01f;

	euler.x += yoffset;
	euler.y += xoffset;

	/*state.camera->camera_transform.rotation.x += yoffset;
	state.camera->camera_transform.rotation.y += xoffset;*/







}