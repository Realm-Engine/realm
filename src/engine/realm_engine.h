
#ifndef REALM_ENGINE_H
#define REALM_ENGINE_H
#include "GLFW/glfw3.h"
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include "re_math.h"
#define STB_IMAGE_IMPLEMENTATION
#include "stb_image.h"

#define RE_GLOBAL_DATA_REF "_reGlobalData"
#define RE_USER_DATA_REF "_reUserData"
#define REALM_ENGINE_FUNC static inline
#define MAX_UNIFORMS GL_MAX_VERTEX_UNIFORM_COMPONENTS + GL_MAX_FRAGMENT_UNIFORM_COMPONENTS

//Graphics API defintions

//Structs and Enums

struct re_shader_t;
struct re_shader_program_t;
struct re_vertex_attr_desc_t;
struct re_vertex_buffer_t;
struct re_shader_block_t;
struct re_gfx_pipeline_t;

typedef enum re_result_t
{
	RE_OK,
	RE_ERROR
} re_result_t;

typedef struct re_global_data_t
{
	mat4x4 view_projection;
} re_global_data_t;

typedef enum re_vertex_type_t
{
	FLOAT = 0x4011,
	FLOAT2 = 0x4021,
	FLOAT3 = 0x4031,
	FLOAT4 = 0x4041

}re_vertex_type_t;

typedef enum re_user_data_var_types
{
	RE_VECTOR = FLOAT4,
	RE_MATRIX = 0x4101,
	RE_FLOAT = FLOAT,
	RE_TEXTURE2D = 0x101F
}re_user_data_var_types;

#define SHADER_VAR_BYTES(var)  ((int)(var >> 8) >> 4)
#define SHADER_VAR_ELEMENTS(var)  (((int) var & 0x0FF0) >> 4)
#define SHADER_VAR_TYPE(var) ((int) var & 0x000F)
#define SHADER_VAR_SIZE(var) (SHADER_VAR_BYTES(var) * SHADER_VAR_ELEMENTS(var) )
typedef struct re_user_data_layout_t
{
	uint32_t num_vars;
	char** var_names;
	re_user_data_var_types* var_types;
	int32_t* var_offsets;
	uint32_t block_size;


}re_user_data_layout_t;


typedef enum re_image_format
{
	RGBA8,
	SRGB

}re_image_format;
typedef enum re_image_type
{
	CUBEMAP,
	TEXTURE2D,
	TEXTURE3D,
	TEXTURE2DARRAY

}re_image_type;

typedef enum re_texture_filter_func
{
	NEAREST,
	LINEAR
}re_texture_filter_func;
typedef enum re_texture_wrap_func
{
	CLAMP_TO_EDGE,
	CLAMP_TO_BORDER,
	REPEAT,

}re_texture_wrap_func;

typedef struct re_texture_desc_t
{
	int32_t width;
	int32_t height;
	re_image_format format;
	re_image_type type;
	re_texture_filter_func filter;
	re_texture_wrap_func wrap;

}re_texture_desc_t;

typedef struct re_texture_t
{
	unsigned char* data;
	int32_t width;
	int32_t height;
	re_image_format format;
	re_image_type type;
	uint32_t  _handle;
	int32_t channels;
	re_texture_filter_func filter;
	re_texture_wrap_func wrap;


}re_texture_t;




typedef struct re_mesh_t
{
	vec3* positions;
	vec3* normals;
	vec2* texcoords;
	uint32_t* triangles;
	uint16_t mesh_size;
}re_mesh_t;



typedef struct re_app_desc_t
{
	int width;
	int height; 
	char title[64];
}re_app_desc_t;

typedef enum re_key_action_t
{
	KEY_DOWN,
	KEY_UP,
	KEY_REPEAT
}re_key_action_t;

typedef enum re_mouse_button_action_t
{
	MOUSE_DOWN,
	MOUSE_UP


}re_mouse_button_action_t;

typedef enum re_attribute_slot
{
	RE_POSITION_ATTRIBUTE,
	RE_TEXCOORD_ATTRIBUTE,
	RE_NORMAL_ATTRIBUTE

}re_attribute_slot;

typedef struct _re_global_state_t
{
	uint32_t _num_textures_active;


} _re_global_state_t;
struct re_context_t;
typedef struct re_event_handler_desc_t
{
	void(*on_update)(struct re_context_t* ctx);
	void(*on_start)(struct re_context_t* ctx);
	void(*on_window_resize)(struct re_context_t* ctx, int32_t width, int32_t height);
	void(*on_user_mouse_move)(struct re_context_t* ctx, float x, float y, float last_x, float last_y);
	void(*on_user_mouse_action)(struct re_context_t* ctx, re_mouse_button_action_t action, int32_t button);
	void(*on_user_key_action)(struct re_context_t* ctx, re_key_action_t action, int32_t key);

}re_event_handler_desc_t;


typedef struct re_context_t
{
	GLFWwindow* _window;
	re_app_desc_t app;
	re_event_handler_desc_t event_handlers;
	float _mouse_last_x;
	float _mouse_last_y;

}re_context_t;



typedef enum re_projection_type
{
	PERSPECTIVE,
	ORTHOGRAPHIC


}re_projection_type;

typedef struct re_camera_t
{
	re_transform_t camera_transform;
	float fov_degrees;
	vec2 size;
	float far_plane;
	float near_plane;
	re_projection_type projection_type;

}re_camera_t;

typedef struct re_view_desc_t
{
	float fov_angle;
	vec2 size;
	float near_plane;
	float far_plane;


}re_view_desc_t;



#define _GET_GLFW_USERPOINTER(ctx,window) re_context_t* ctx = (re_context_t*)glfwGetWindowUserPointer(window)

REALM_ENGINE_FUNC void _re_handle_window_resize(GLFWwindow* window, int width, int height)
{
	re_context_t* ctx = (re_context_t*)glfwGetWindowUserPointer(window);
	if (ctx->event_handlers.on_window_resize != NULL)
	{
		ctx->event_handlers.on_window_resize(ctx, width, height);
	}
}

REALM_ENGINE_FUNC void _re_handle_mouse_action(GLFWwindow* window, int button, int action, int mods)
{

	_GET_GLFW_USERPOINTER(ctx, window);
	if (ctx->event_handlers.on_user_mouse_action != NULL)
	{
		re_mouse_button_action_t re_action;
		switch (action)
		{
		case GLFW_PRESS:
			re_action = MOUSE_DOWN;
			break;
		case GLFW_RELEASE:
			re_action = MOUSE_UP;
			break;
		default:
			re_action = MOUSE_DOWN;
			break;
		}

		ctx->event_handlers.on_user_mouse_action(ctx, re_action, button);


	}


}

REALM_ENGINE_FUNC void _re_handle_mouse_pos(GLFWwindow* window, double x, double y)
{
	_GET_GLFW_USERPOINTER(ctx, window);
	if (ctx->event_handlers.on_user_mouse_move != NULL)
	{
		ctx->event_handlers.on_user_mouse_move(ctx, x, y, ctx->_mouse_last_x, ctx->_mouse_last_y);
		ctx->_mouse_last_x = x;
		ctx->_mouse_last_y = y;
	}

}

REALM_ENGINE_FUNC void _re_handle_key_action(GLFWwindow* window, int key, int scancode,int action, int mods)
{
	_GET_GLFW_USERPOINTER(ctx, window);
	if (ctx->event_handlers.on_user_key_action != NULL)
	{
		re_key_action_t re_action;
		switch (action)
		{
		case GLFW_PRESS:
			re_action = KEY_DOWN;
			break;
		case GLFW_RELEASE:
			re_action = KEY_UP;
			break;
		default:
			re_action = KEY_DOWN;
			break;
		}
		ctx->event_handlers.on_user_key_action(ctx, re_action, key);

	}


}


REALM_ENGINE_FUNC re_context_t* re_init(re_app_desc_t app) {
	if (!glfwInit())
	{
		printf("Could not init glfw!\n");
	}
	re_context_t* ctx = (re_context_t*)malloc(sizeof(re_context_t));
	memset(&ctx->event_handlers, NULL, sizeof(re_event_handler_desc_t));
	ctx->_window = glfwCreateWindow(app.width, app.height, app.title, NULL, NULL);
	memcpy(&ctx->app, &app, sizeof(re_context_t));
	glfwMakeContextCurrent(ctx->_window);
	glfwSetWindowUserPointer(ctx->_window, ctx);
	glfwSetWindowSizeCallback(ctx->_window, &_re_handle_window_resize);
	glfwSetMouseButtonCallback(ctx->_window, &_re_handle_mouse_action);
	glfwSetCursorPosCallback(ctx->_window, &_re_handle_mouse_pos);
	glfwSetKeyCallback(ctx->_window, &_re_handle_key_action);
	return ctx;

	
}



REALM_ENGINE_FUNC void re_set_event_handler(re_context_t* ctx, re_event_handler_desc_t ev)
{
	memcpy(&ctx->event_handlers, &ev, sizeof(re_event_handler_desc_t));
}

REALM_ENGINE_FUNC void _re_poll_events()
{
	glfwPollEvents();
}
REALM_ENGINE_FUNC void _re_swap_buffers(re_context_t* ctx)
{
	glfwSwapBuffers(ctx->_window);
}

REALM_ENGINE_FUNC void re_start(re_context_t* ctx)
{
	ctx->event_handlers.on_start(ctx);
	while (!glfwWindowShouldClose(ctx->_window))
	{
		
		ctx->event_handlers.on_update(ctx);
		_re_swap_buffers(ctx);
		_re_poll_events();

	}



}

REALM_ENGINE_FUNC re_result_t re_context_size(re_context_t* ctx,int* width, int* height)
{
	glfwGetWindowSize(ctx->_window, width, height);
	return RE_OK;
}
 
REALM_ENGINE_FUNC vec3* re_apply_transform(re_transform_t transform, re_mesh_t* mesh)
{
	
	vec3* result = (vec3*)malloc(sizeof(vec3) * mesh->mesh_size);
	mat4x4 model = compute_transform(transform);
	int i;
	for (i = 0; i < 4; i++)
	{
		vec4 ws = mat4_mul_vec4(model, vec4_from_vec3(mesh->positions[i], 1.0f));
		result[i] = vec3_from_vec4(ws );
	}
	
	return result;

}

REALM_ENGINE_FUNC re_result_t re_read_text(const char* filePath, char* buffer)
{
	FILE* fp;
	fp = fopen(filePath, "r");
	if (fp == NULL)
	{
		return RE_ERROR;
	}
	char ch = 0;
	char* ptr = buffer;
	while ((ch = fgetc(fp)) != EOF)
	{
		*ptr = ch;
		ptr++;
	}
	*ptr = '\0';
	fclose(fp);
	return RE_OK;



}

REALM_ENGINE_FUNC re_camera_t*  re_create_camera(re_projection_type type, re_view_desc_t view_desc)
{
	re_camera_t* camera = (re_camera_t*)malloc(sizeof(re_camera_t));
	camera->projection_type = type;
	camera->camera_transform = new_transform;
	camera->size = view_desc.size;
	camera->near_plane = view_desc.near_plane;
	camera->far_plane = view_desc.far_plane;
	camera->fov_degrees = view_desc.fov_angle;
	camera->camera_transform.euler_rotation = new_vec3(0, 0, 0);
	camera->camera_transform.rotation = vec4_zero;
	return camera;

}

REALM_ENGINE_FUNC vec3 re_compute_camera_front(re_camera_t* camera)
{
	vec4 forward = mat4_mul_vec4(quat_rotation_matrix(camera->camera_transform.rotation), vec4_from_vec3(vec3_forward,1.0f));
	return vec3_normalize(vec3_from_vec4(forward));

}

REALM_ENGINE_FUNC vec3 re_compute_camera_up(re_camera_t* camera)
{
	vec4 up = mat4_mul_vec4(quat_rotation_matrix(camera->camera_transform.rotation), vec4_from_vec3(vec3_up, 1.0f));
	return vec3_normalize(vec3_from_vec4(up));
}

REALM_ENGINE_FUNC vec3 re_compute_camera_right(re_camera_t* camera)
{
	vec4 right = mat4_mul_vec4(quat_rotation_matrix(camera->camera_transform.rotation), vec4_from_vec3(vec3_right, 1.0f));
	return vec3_normalize(vec3_from_vec4(right));
}

REALM_ENGINE_FUNC mat4x4 re_camera_lookat(re_camera_t* camera)
{
	vec3 front = re_compute_camera_front(camera);
	front = vec3_normalize(front);
	vec3 up = re_compute_camera_up(camera);
	vec3 centre = vec3_add(camera->camera_transform.position, front);
	mat4x4 R = mat4_lookat(camera->camera_transform.position, centre, up);
	
	return R;

}

REALM_ENGINE_FUNC mat4x4 re_camera_projection(re_camera_t* camera)
{
	mat4x4 projection;
	switch (camera->projection_type)
	{
	case PERSPECTIVE:
		projection = re_perspective(deg_to_rad(camera->fov_degrees), camera->size.x / camera->size.y, camera->near_plane, camera->far_plane);
		break;
	case ORTHOGRAPHIC:
		projection = re_orthographic(camera->size.x, 0, 0, camera->size.y, camera->near_plane, camera->far_plane);
		break;
	default:
		projection = re_orthographic(camera->size.x, 0, 0, camera->size.y, camera->near_plane, camera->far_plane);
		break;
	}
	return projection;
}


REALM_ENGINE_FUNC mat4x4 re_compute_view_projection(re_camera_t* camera)
{
	mat4x4 projection = re_camera_projection(camera);
	mat4x4 view = re_camera_lookat(camera);
	//mat4x4 view = compute_transform(camera->camera_transform);
	return mat4_mul(projection, view);

}

REALM_ENGINE_FUNC re_result_t re_read_image(const char* path, re_texture_t* texture,re_texture_desc_t desc)
{
	texture->data = stbi_load(path, &texture->width, &texture->height, &texture->channels, 0);
	texture->filter = desc.filter;
	texture->wrap = desc.wrap;
	texture->type = desc.type;
	return RE_OK;


}

REALM_ENGINE_FUNC re_result_t re_free_texture_data(re_texture_t* texture)
{
	stbi_image_free(texture->data);
	return RE_OK;
}

//CONTAINER
#define linked_list_decl(T)\
typedef struct _linked_list_##T\
{\
	T value;\
	struct _linked_list_##T * _next;\
} _linked_list_##T;\


#define linked_list(T) _linked_list_##T
linked_list_decl(int)


#endif


#include "gfx_ogl.h"
