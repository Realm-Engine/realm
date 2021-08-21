#ifndef REALM_GAME_H
#define REALM_GAME_H

#include "engine/realm_engine.h"
#include "resource.c"


typedef struct realm_state
{
	re_camera_t* camera;
}realm_state;


realm_state state;
re_shader_program_t scene_shader;
re_shader_program_t screen_shader;
re_renderpass_t* scene_pass;
re_actor_t actors[64];
re_actor_t* scene_root;
re_actor_t* square_actor;
re_actor_t* other_actor;
void realm_start(re_context_t ctx);
void realm_update(re_context_t ctx);
void on_window_resize(re_context_t* ctx, int32_t width, int32_t height);
void on_key_action(re_context_t* ctx, re_key_action_t action, int32_t key);
void on_mouse_action(re_context_t* ctx, re_mouse_button_action_t action, int32_t button);
void on_mouse_pos(re_context_t* ctx, float x, float y, float last_x, float last_y);
void realm_main();
#endif // !REALM_GAME_H