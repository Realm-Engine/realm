#ifndef REALM_GAME_H
#define REALM_GAME_H

#include "engine/realm_engine.h"
#include "resource.c"

#define TINYOBJ_LOADER_C_IMPLEMENTATION
#include "tinyobj_loader_c.h"

typedef struct realm_state
{
	re_camera_t* camera;
	re_mainlight_t mainlight;
}realm_state;


realm_state state;
re_shader_program_t scene_shader;
re_shader_program_t screen_shader;
re_renderpass_t* scene_pass;
re_actor_t actors[64];
re_actor_t* scene_root;
re_actor_t* square_actor;
re_actor_t* light_actor;
re_actor_t* other_actor;
re_texture_t* wall_texture;
re_texture_t* wall_normal_texture;
re_pointlight_t light;
void realm_start(re_context_t ctx);
void realm_update(re_context_t ctx);
void on_window_resize(re_context_t* ctx, int32_t width, int32_t height);
void on_key_action(re_context_t* ctx, re_key_action_t action, int32_t key);
void on_mouse_action(re_context_t* ctx, re_mouse_button_action_t action, int32_t button);
void on_mouse_pos(re_context_t* ctx, float x, float y, float last_x, float last_y);


void obj_to_mesh( tinyobj_attrib_t* attributes,  tinyobj_shape_t* shapes, re_mesh_t* mesh);
re_mesh_t* generate_sphere(uint32_t resolution);
void generate_cube(uint32_t resolution, re_mesh_t* mesh);
void generate_plane(vec3 normal, uint32_t resolution, re_mesh_t* mesh, uint32_t index_offset);
#endif // !REALM_GAME_H