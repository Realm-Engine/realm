
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
#define REALM_ENGINE_FUNC static
#define MAX_UNIFORMS GL_MAX_VERTEX_UNIFORM_COMPONENTS + GL_MAX_FRAGMENT_UNIFORM_COMPONENTS
#define _RE_SCENEGRAPH_CHILD_CHUNK_AMOUNT 5
#define _RE_VECTOR_CHUNK_SIZE 5

//Graphics API defintions

//Structs and Enums

/*struct re_shader_t;
struct re_shader_program_t;
struct re_vertex_attr_desc_t;
struct re_vertex_buffer_t;
struct re_shader_block_t;
struct re_gfx_pipeline_t;*/


#pragma region Containers
//CONTAINER
#pragma region LinkedList
#define linked_list_decl(T)\
typedef struct _##T##_node\
{ \
	struct _##T##_node * next;\
	T value;\
}_##T##_node;\
static inline _##T##_node* _linked_list_##T##_enumerate_func(_##T##_node* current, T* val)\
{\
	if(current->next == NULL)\
	{\
		return NULL;\
	}\
	*val = current->next->value;\
	return current->next;\
}\
static inline _##T##_node* _##T##_node_create(T val)\
{\
	_##T##_node* node = (_##T##_node*)malloc(sizeof(_##T##_node));\
	node->value = val;\
	node->next = NULL;\
	return node;\
}\
typedef struct _linked_list_##T\
{\
	_##T##_node * _head;\
} _linked_list_##T;\
static inline _##T##_node* _linked_list_##T##_append(_linked_list_##T * ll,T value)\
{\
	_##T##_node* current = ll->_head;\
	if(current == NULL)\
	{\
		ll->_head = _##T##_node_create(value);\
		return ll->_head;\
	}\
	while(current->next != NULL)\
	{\
		current = current->next;\
	}\
	current->next = _##T##_node_create(value);\
	return current->next;\
}\
static inline void _linked_list_##T##_free(_linked_list_##T * ll)\
{\
	_##T##_node* current = ll->_head;\
	while(current != NULL)\
	{\
		_##T##_node* temp = current;\
		current = current->next;\
		free(temp);\
	}\
}\

#define linked_list(T) _linked_list_##T
#define linked_list_append(T,ll,v) _linked_list_##T##_append(ll,v);
#define linked_list_traverse(T,v,e)\
T v = (e)._head->value;\
_##T##_node* i;\
for(i = (e)._head;i != NULL; i = _linked_list_##T##_enumerate_func((i),(&v)))
#define linked_list_free(T,ll) _linked_list_##T##_free(ll);
#define vector(T) _vector_##T


#define vector_decl(T)\
\
typedef struct vector(T)\
{\
	T* elements;\
	size_t count;\
	size_t capacity;\
}vector(T);\
static inline vector(T) _new_vector_##T(size_t reserve)\
{\
	vector(T) v;\
	v.elements = (T *)malloc(sizeof(T) * reserve);\
	memset(v.elements,0,sizeof(T) * reserve);\
	v.capacity = reserve;\
	v.count = 0;\
	return v;\
}\
static inline void _vector_##T##_resize(vector(T) * vector, size_t size)\
{\
	vector->capacity = size;\
	vector->elements = ( T *)realloc(vector->elements,sizeof( T ) * size);\
}\
static inline T * _vector_##T##_insert(vector(T) * vector,T value)\
{\
	if(vector->count + 1 > vector->capacity)\
	{\
		size_t resize_amount = 0;\
		if(vector->capacity == 0)\
		{\
			resize_amount = _RE_VECTOR_CHUNK_SIZE;\
		}\
		else\
		{\
			int mod = _RE_VECTOR_CHUNK_SIZE % vector->capacity;\
			resize_amount = mod + vector->capacity;\
		}\
		_vector_##T##_resize(vector, resize_amount); \
	}\
	vector->elements[vector->count] = value; \
	T * new_element = &vector->elements[vector->count];\
	vector->count += 1;\
	return new_element;\
}\
static inline T _vector_##T##_get(vector(T)* vector, size_t index )\
{\
	return vector->elements[index];\
}\
static inline void _vector_##T##_set(vector(T)* vector, size_t index, T value )\
{\
	vector->elements[index] = value;\
}\


#define vector_insert(T,vector,value) _vector_##T##_insert(vector,value)
#define new_vector(T,size) _new_vector_##T(size)
#define vector_resize(T,vector,size) _vector_##T##_resize(vector,size)
#define vector_get(T,vector,index) _vector_##T##_get(vector,index)
#define vector_set(T,vector,index,value) _vector_##T##_get(vector,index,value)

vector_decl(uint32_t)


#pragma endregion


typedef enum re_result_t
{
	RE_OK,
	RE_ERROR
} re_result_t;


typedef struct _re_camera_data_t
{
	float near_plane;
	float far_plane;
	vec2 screen_size;
}_re_camera_data_t;

typedef struct re_mainlight_t
{
	re_transform_t transform;
	vec3 color;
	float intensity;


}re_mainlight_t;


typedef struct re_pointlight_t
{
	re_transform_t transform;
	vec3 color;
	float instensity;
	

}re_pointlight_t;

vector_decl(vec4);


typedef struct re_pointlights_data
{
	vec4 positions[4];
	vec4 colors[4];
	vec2 num_lights;

}re_pointlights_data;


typedef struct re_lighting_data_t
{
	vec4 ambient_light;
	vec4 mainlight_direction;
	vec4 mainlight_color;
	re_pointlights_data pointlights;

}re_lighting_data_t;

typedef struct re_global_data_t
{
	mat4x4 view_projection;
	_re_camera_data_t camera_data;
	re_lighting_data_t lighting_data;
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
	uint32_t* _hashes;
	re_user_data_var_types* var_types;
	int32_t* var_offsets;
	uint32_t block_size;


}re_user_data_layout_t;


typedef enum re_image_format
{
	RGB,
	RGBA8,
	SRGB,
	DEPTH_STENCIL,
	DEPTH

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




vector_decl(re_texture_t)



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


struct re_context_t;
typedef struct re_event_handler_desc_t
{
	void(*on_update)(struct re_context_t ctx);
	void(*on_start)(struct re_context_t ctx);
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
	vec3 camera_front;

}re_camera_t;


typedef struct re_view_desc_t
{
	float fov_angle;
	vec2 size;
	float near_plane;
	float far_plane;


}re_view_desc_t;




re_context_t _re_context;

struct re_scenegraph_t;

typedef struct re_material_property_t
{
	uint32_t id;
	re_user_data_var_types type;
	uint8_t* _data;
}re_material_property_t;



vector_decl(re_material_property_t)
typedef vector(re_material_property_t) re_material_properties_list;

typedef struct re_mesh_t
{
	vec3* positions;
	vec3* normals;
	vec2* texcoords;
	uint32_t* triangles;
	uint16_t mesh_size;
	uint16_t num_triangles;

}re_mesh_t;

typedef struct re_material_textures_t
{
	vector(uint32_t) texture_ids;
	vector(re_texture_t) textures;


}re_material_textures_t;

typedef struct re_actor_t
{
	re_mesh_t mesh;
	re_transform_t transform;
	struct re_scenegraph_t* _scenegraph_node;
	re_material_properties_list material_properties;
	re_material_textures_t material_textures;


}re_actor_t;



typedef struct re_scenegraph_t
{
	re_actor_t* root;
	struct re_scenegraph_t** children;
	struct re_scenegraph_t* parent;
	uint16_t num_children;

}re_scenegraph_t;



#pragma region Function defines
REALM_ENGINE_FUNC void _re_handle_window_resize(GLFWwindow* window, int width, int height);
REALM_ENGINE_FUNC void _re_handle_mouse_action(GLFWwindow* window, int button, int action, int mods);
REALM_ENGINE_FUNC void _re_handle_mouse_pos(GLFWwindow* window, double x, double y);
REALM_ENGINE_FUNC void _re_handle_key_action(GLFWwindow* window, int key, int scancode, int action, int mods);
REALM_ENGINE_FUNC re_result_t re_init(re_app_desc_t app);
REALM_ENGINE_FUNC void re_set_event_handler(re_event_handler_desc_t ev);
REALM_ENGINE_FUNC void _re_poll_events();
REALM_ENGINE_FUNC void _re_swap_buffers();
REALM_ENGINE_FUNC void re_start();
REALM_ENGINE_FUNC re_result_t re_context_size(int* width, int* height);
REALM_ENGINE_FUNC size_t re_apply_transform(re_transform_t transform, re_mesh_t* mesh,vec3* positions, vec3* normals);
REALM_ENGINE_FUNC re_result_t re_read_text(const char* filePath, char* buffer);
REALM_ENGINE_FUNC re_camera_t* re_create_camera(re_projection_type type, re_view_desc_t view_desc);
REALM_ENGINE_FUNC vec3 re_compute_camera_front(re_camera_t* camera);
REALM_ENGINE_FUNC vec3 re_compute_camera_up(re_camera_t* camera);
REALM_ENGINE_FUNC vec3 re_compute_camera_right(re_camera_t* camera);
REALM_ENGINE_FUNC mat4x4 re_camera_lookat(re_camera_t* camera);
REALM_ENGINE_FUNC mat4x4 re_camera_projection(re_camera_t* camera);
REALM_ENGINE_FUNC mat4x4 re_compute_view_projection(re_camera_t* camera);
REALM_ENGINE_FUNC re_result_t re_read_image(const char* path, re_texture_t* texture, re_texture_desc_t desc);
REALM_ENGINE_FUNC re_result_t re_free_texture_data(re_texture_t* texture);
REALM_ENGINE_FUNC void re_actor_add_child(re_actor_t* parent, re_actor_t* child);
REALM_ENGINE_FUNC re_result_t re_update_vp(mat4x4 matrix);
REALM_ENGINE_FUNC re_result_t re_set_camera_data(re_camera_t* camera);
REALM_ENGINE_FUNC void re_update_main_light(re_mainlight_t* mainlight);
REALM_ENGINE_FUNC void re_update_ambient_light(vec3 color, float strength);
REALM_ENGINE_FUNC re_result_t re_render_scene(re_actor_t* root);
REALM_ENGINE_FUNC void init_actor(re_actor_t* actor);
REALM_ENGINE_FUNC re_scenegraph_t* re_create_scenegraph(re_actor_t* node);
REALM_ENGINE_FUNC void re_fill_mesh(re_mesh_t* mesh, vec3* positions, vec3* normals, vec2* texcoords, uint32_t mesh_size);
REALM_ENGINE_FUNC re_result_t re_set_material_texture(re_material_textures_t* texture_list, const char* name, re_texture_t texture);
REALM_ENGINE_FUNC re_texture_t re_get_material_texture(re_material_textures_t* texture_list, uint32_t id);
REALM_ENGINE_FUNC void re_set_mesh_triangles(re_mesh_t* mesh, uint32_t* triangles, uint32_t num_triangles);
REALM_ENGINE_FUNC void re_set_material_vector(re_material_properties_list* material_list, const char* name, vec4 value);
REALM_ENGINE_FUNC vec4 re_get_material_vector(re_material_properties_list* material_list, const char* name);
REALM_ENGINE_FUNC void re_set_userdata_properties_from_materials(re_user_data_layout_t* layout, re_material_properties_list* materials);
REALM_ENGINE_FUNC uint32_t re_adler32_str(const char* buffer);
REALM_ENGINE_FUNC long re_get_file_size(const char* file);

#define material_id(name) re_adler32_str(name);

#ifndef RE_GFX_IMPL
#define RE_GFX_IMPL
#endif
#include "gfx_ogl.h"
#pragma endregion

REALM_ENGINE_FUNC void re_draw_scene_recursive(re_actor_t* node, re_renderpass_t* renderpass);


#define _GET_GLFW_USERPOINTER(ctx,window) re_context_t* ctx = (re_context_t*)glfwGetWindowUserPointer(window)
#ifdef REALM_ENGINE_IMPL

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

REALM_ENGINE_FUNC void _re_handle_key_action(GLFWwindow* window, int key, int scancode, int action, int mods)
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


REALM_ENGINE_FUNC uint32_t re_adler32_str(const char* buffer)
{

	const char* ptr = buffer;
	size_t i = 0;
	uint32_t s1 = 1;
	uint32_t s2 = 0;
	while (*ptr != '\0')
	{
		s1 = (s1 + *ptr) % 65521;
		s2 = (s1 + s1) % 65521;
		i++;
		ptr++;
	}
	return (s2 << 16) | s1;

}

REALM_ENGINE_FUNC re_result_t re_init(re_app_desc_t app) {
	if (!glfwInit())
	{
		printf("Could not init glfw!\n");
	}

	memset(&_re_context.event_handlers, NULL, sizeof(re_event_handler_desc_t));
	_re_context._window = glfwCreateWindow(app.width, app.height, app.title, NULL, NULL);
	_re_context.app = app;
	glfwMakeContextCurrent(_re_context._window);
	glfwSetWindowUserPointer(_re_context._window, &_re_context);
	glfwSetWindowSizeCallback(_re_context._window, &_re_handle_window_resize);
	glfwSetMouseButtonCallback(_re_context._window, &_re_handle_mouse_action);
	glfwGetCursorPos(_re_context._window, &_re_context._mouse_last_x, &_re_context._mouse_last_y);
	glfwSetCursorPosCallback(_re_context._window, &_re_handle_mouse_pos);
	glfwSetKeyCallback(_re_context._window, &_re_handle_key_action);
	return RE_OK;


}



REALM_ENGINE_FUNC void re_set_event_handler(re_event_handler_desc_t ev)
{
	_re_context.event_handlers = ev;
}

REALM_ENGINE_FUNC void _re_poll_events()
{
	glfwPollEvents();
}
REALM_ENGINE_FUNC void _re_swap_buffers()
{
	glfwSwapBuffers(_re_context._window);
}

REALM_ENGINE_FUNC void re_start()
{
	_re_context.event_handlers.on_start(_re_context);
	while (!glfwWindowShouldClose(_re_context._window))
	{

		_re_context.event_handlers.on_update(_re_context);
		_re_swap_buffers();
		_re_poll_events();

	}



}

REALM_ENGINE_FUNC re_result_t re_context_size(int* width, int* height)
{
	glfwGetWindowSize(_re_context._window, width, height);
	return RE_OK;
}

REALM_ENGINE_FUNC size_t re_apply_transform(re_transform_t transform, re_mesh_t* mesh, vec3* positions, vec3* normals)
{

	mat4x4 model = compute_transform(transform);
	mat4x4 inv_model = mat4_inverse(model);
	mat4x4 trans_inv = mat4_transpose(inv_model);
	int i;
	for (i = 0; i < 4; i++)
	{
		vec4 wsPos = mat4_mul_vec4(model, vec4_from_vec3(mesh->positions[i], 1.0f));
		vec4 wsNormal = mat4_mul_vec4(trans_inv, vec4_from_vec3(mesh->normals[i], 1.0f));
		positions[i] = vec3_from_vec4(wsPos);
		normals[i] = vec3_from_vec4(wsNormal);
		
	}

}

REALM_ENGINE_FUNC long re_get_file_size(const char* path)
{
	FILE* fp;
	fp = fopen(path, "r");
	if (fp == NULL)
	{
		return -1;
	}

	fseek(fp, 0, SEEK_END);
	return ftell(fp);


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

REALM_ENGINE_FUNC re_camera_t* re_create_camera(re_projection_type type, re_view_desc_t view_desc)
{
	re_camera_t* camera = (re_camera_t*)malloc(sizeof(re_camera_t));
	camera->projection_type = type;
	camera->camera_transform = new_transform;
	
	camera->size = view_desc.size;
	camera->near_plane = view_desc.near_plane;
	camera->far_plane = view_desc.far_plane;
	camera->fov_degrees = view_desc.fov_angle;

	return camera;

}



REALM_ENGINE_FUNC vec3 re_compute_camera_front(re_camera_t* camera)
{
	vec4 forward = mat4_mul_vec4(quat_rotation_matrix(camera->camera_transform.rotation), vec4_from_vec3(vec3_forward, 1.0f));
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

REALM_ENGINE_FUNC re_result_t re_read_image(const char* path, re_texture_t* texture, re_texture_desc_t desc)
{
	texture->data = stbi_load(path, &texture->width, &texture->height, &texture->channels, 0);
	texture->filter = desc.filter;
	texture->wrap = desc.wrap;
	texture->type = desc.type;
	switch (texture->channels)
	{
	case 3:
		texture->format = RGB;
		break;
	case 4:
		texture->format = RGBA8;
		break;
	default:
		break;
	}
	return RE_OK;


}

REALM_ENGINE_FUNC re_add_pointlight(re_pointlight_t* light)
{
	re_gfx_pipeline_t* gfx = RE_GRAPHICS_PIPELINE;



	mat4x4 M = re_mat4_identity();
	M = mat4_scale(M, vec3_one);
	M = mat4_translate(M, light->transform.position);
	vec4 pos = mat4_mul_vec4(M, vec4_one);
	int index = gfx->re_global_data->lighting_data.pointlights.num_lights.x;
	vec4 color = vec4_from_vec3(light->color, light->instensity);
	gfx->re_global_data->lighting_data.pointlights.positions[index] = pos;
	gfx->re_global_data->lighting_data.pointlights.colors[index] = color;
	gfx->re_global_data->lighting_data.pointlights.num_lights.x += 1;
}


REALM_ENGINE_FUNC void re_update_ambient_light(vec3 color, float strength)
{
	re_gfx_pipeline_t* pipeline = RE_GRAPHICS_PIPELINE;
	pipeline->re_global_data->lighting_data.ambient_light = vec4_from_vec3(color, strength);

}

REALM_ENGINE_FUNC void re_update_main_light(re_mainlight_t* mainlight)
{
	re_gfx_pipeline_t* pipeline = RE_GRAPHICS_PIPELINE;
	pipeline->re_global_data->lighting_data.mainlight_color = vec4_from_vec3(mainlight->color, mainlight->intensity);
	mat4x4 M = re_mat4_identity();
	quaternion norm_rot = vec4_normalize(mainlight->transform.rotation);
	mat4x4 rotation = quat_rotation_matrix(norm_rot);
	vec4 dir = mat4_mul_vec4(quat_rotation_matrix(mainlight->transform.rotation), vec4_from_vec3(vec3_forward, 1.0f));
	//dir = vec4_normalize(dir);

	pipeline->re_global_data->lighting_data.mainlight_direction = dir;


}
REALM_ENGINE_FUNC re_result_t re_set_camera_data(re_camera_t* camera)
{
	re_gfx_pipeline_t* pipeline = RE_GRAPHICS_PIPELINE;
	_re_camera_data_t* camera_data = &pipeline->re_global_data->camera_data;
	camera_data->far_plane = camera->far_plane;
	camera_data->near_plane = camera->near_plane;
	camera_data->screen_size = new_vec2(camera->size.x, camera->size.y);
}

REALM_ENGINE_FUNC re_result_t re_free_texture_data(re_texture_t* texture)
{
	stbi_image_free(texture->data);
	return RE_OK;
}



REALM_ENGINE_FUNC re_scenegraph_t* re_create_scenegraph(re_actor_t* actor)
{
	re_scenegraph_t* graph;
	graph = (re_scenegraph_t*)malloc(sizeof(re_scenegraph_t));
	graph->parent = NULL;
	graph->children = (re_scenegraph_t**)malloc(sizeof(re_scenegraph_t*) * _RE_SCENEGRAPH_CHILD_CHUNK_AMOUNT);
	graph->num_children = 0;
	graph->root = actor;
	return graph;
}


REALM_ENGINE_FUNC void init_actor(re_actor_t* actor)
{
	memset(actor, 0, sizeof(re_actor_t));
	actor->_scenegraph_node = re_create_scenegraph(actor);
	actor->transform = new_transform;
	actor->material_properties = new_vector(re_material_property_t, _RE_VECTOR_CHUNK_SIZE);

}

REALM_ENGINE_FUNC re_material_property_t* re_find_material_property(re_material_properties_list* material_list, uint32_t id)
{

	int i;
	re_material_property_t* target_property = NULL;
	for (i = 0; i < material_list->count; i++)
	{
		re_material_property_t property = vector_get(re_material_property_t, material_list, i);
		if (property.id == id)
		{
			target_property = &property;
		}
	}

	return target_property;

}

REALM_ENGINE_FUNC re_texture_t re_get_material_texture(re_material_textures_t* list, uint32_t id)
{

	int i;
	int target_index = -1;
	for (i = 0; i < list->textures.count; i++)
	{
		if (list->texture_ids.elements[i] == id)
		{
			target_index = i;
		}
	}
	re_texture_t result;
	if (target_index >= 0)
	{
		result = list->textures.elements[i];

	}
	else
	{
		memset(&result, 0, sizeof(re_texture_t));
	}

	return result;


}

REALM_ENGINE_FUNC re_result_t re_set_material_texture(re_material_textures_t* list, const char* name, re_texture_t value)
{
	uint32_t id = material_id(name);
	int i;
	int target_index = -1;
	for (i = 0; i < list->textures.count; i++)
	{
		if (list->texture_ids.elements[i] == id)
		{
			target_index = i;
		}
	}
	if (target_index == -1)
	{

		vector_insert(re_texture_t, &list->textures, value);
		vector_insert(uint32_t, &list->texture_ids, id);
		target_index = list->textures.count - 1;

	}
	else
	{
		memcpy(&list->textures.elements[target_index], &value, sizeof(re_texture_t));
		memcpy(&list->texture_ids.elements[target_index], &id, sizeof(uint32_t));
	}


}

REALM_ENGINE_FUNC void re_set_material_vector(re_material_properties_list* material_list,const char* name, vec4 value)
{
	
	uint32_t id = material_id(name);

	re_material_property_t* target_property = re_find_material_property(material_list,id);
	
	if (target_property == NULL)
	{
		re_material_property_t new_property = (re_material_property_t){
			.id = id,
			.type = RE_VECTOR,
			._data = (uint8_t*)malloc(sizeof(vec4))
			
		};
		
		target_property = vector_insert(re_material_property_t, material_list, new_property);


	}

	memcpy(target_property->_data, &value, sizeof(vec4));
}

REALM_ENGINE_FUNC vec4 re_get_material_vector(re_material_properties_list* material_list, const char* name)
{
	uint32_t id = material_id(name);

	re_material_property_t* target_property = re_find_material_property(material_list,id);
	
	vec4 result;
	if (target_property != NULL)
	{
		memcpy(&result, target_property->_data, sizeof(vec4));


	}
	else
	{
		result = vec4_zero;
	}

	return result;
}

REALM_ENGINE_FUNC void re_set_userdata_properties_from_materials(re_user_data_layout_t* layout, re_material_properties_list* materials)
{
	int i;
	for (i = 0; i < layout->num_vars; i++)
	{
		re_material_property_t target_property;
		int j;
		for (j = 0; j < materials->count; j++)
		{
			if (vector_get(re_material_property_t, materials, j).id == layout->_hashes[i])
			{
				target_property = vector_get(re_material_property_t, materials, j);
			}


		}

		switch (layout->var_types[i])
		{
		case RE_VECTOR:
			re_set_userdata_vector(layout, layout->var_names[i], re_get_material_vector(materials, layout->var_names[i]));
			break;
		default:
			break;
		}


	}


}

REALM_ENGINE_FUNC re_set_samplers_from_material(re_material_textures_t* list, re_shader_program_t* program)
{
	int i;
	for (i = 0; i < list->textures.count; i++)
	{
		re_texture_t texture = re_get_material_texture(list, list->texture_ids.elements[i]);
		

	}
}

REALM_ENGINE_FUNC void re_actor_add_child(re_actor_t* parent, re_actor_t* child)
{
	if (parent->_scenegraph_node->num_children % 5 == 0 && parent->_scenegraph_node->num_children != 0)
	{
		uint16_t num_elements = parent->_scenegraph_node->num_children;

		parent->_scenegraph_node->children = (re_scenegraph_t**)realloc(parent->_scenegraph_node->children, sizeof(re_scenegraph_t*) * (num_elements / _RE_SCENEGRAPH_CHILD_CHUNK_AMOUNT) + (1 * _RE_SCENEGRAPH_CHILD_CHUNK_AMOUNT));
	}
	parent->_scenegraph_node->children[parent->_scenegraph_node->num_children] = child->_scenegraph_node;
	parent->_scenegraph_node->num_children++;
	child->_scenegraph_node->parent = parent;

}

REALM_ENGINE_FUNC void re_fill_mesh(re_mesh_t* mesh, vec3* positions, vec3* normals, vec2* texcoords, uint32_t mesh_size)
{
	size_t size_positions = sizeof(vec3) * mesh_size;
	size_t size_normals = sizeof(vec3) * mesh_size;
	size_t size_uv = sizeof(vec2) * mesh_size;
	mesh->positions = (vec3*)malloc(size_positions);
	mesh->normals = (vec3*)malloc(size_normals);
	mesh->texcoords = (vec2*)malloc(size_uv);
	memcpy(mesh->positions, positions, size_positions);

	memcpy(mesh->normals, normals, size_normals);
	memcpy(mesh->texcoords, texcoords, size_uv);
	mesh->mesh_size = mesh_size;

}

REALM_ENGINE_FUNC void re_set_mesh_triangles(re_mesh_t* mesh, uint32_t* triangles, uint32_t num_triangles)
{
	mesh->triangles = (uint32_t*)malloc(sizeof(uint32_t) * num_triangles);
	memcpy(mesh->triangles, triangles, sizeof(uint32_t) * num_triangles);
	mesh->num_triangles = num_triangles;
}

REALM_ENGINE_FUNC void re_set_userdata_textures(re_material_textures_t* textures,re_shader_program_t* program)
{
	int i, j;
	_re_sampler_uniform_cache samplers = program->_sampler_cache;
	for (i = 0; i < textures->textures.count; i++)
	{
		for (j = 0; j < samplers._hashes.count; j++)
		{
			uint32_t tex_id = textures->texture_ids.elements[i];
			uint32_t sampler_hash = samplers._hashes.elements[j];
			if (tex_id == sampler_hash)
			{
				GLint loc = samplers._locations.elements[j];
				glBindTextureUnit(loc, textures->textures.elements[i]._handle);
				glUniform1i(loc, samplers._locations.elements[j]);
			}
		}

	}


}

REALM_ENGINE_FUNC void re_draw_scene_recursive(re_actor_t* root,re_renderpass_t* renderpass)
{
	if (root->mesh.mesh_size > 0)
	{
		re_set_userdata_properties_from_materials(&renderpass->_user_data_layout, &root->material_properties);
		re_set_userdata_textures(&root->material_textures, &renderpass->shader_program);
		re_upload_mesh_data(&root->mesh, &root->transform);
		re_draw_triangles(root->mesh.num_triangles);
	}
	int i;
	for (i = 0; i < root->_scenegraph_node->num_children; i++)
	{
		re_scenegraph_t* child = root->_scenegraph_node->children[i];
		re_draw_scene_recursive(child->root,renderpass);
	}


}

REALM_ENGINE_FUNC re_result_t re_render_scene(re_actor_t* root)
{
	re_gfx_pipeline_t* pipeline = RE_GRAPHICS_PIPELINE;


	linked_list_traverse(re_renderpass_t, pass, pipeline->_main_renderpath._linked_list)
	{


		if (pass._user_pass)
		{

			re_bind_shader_block(pipeline->_re_user_data_block, RE_USER_DATA_REF, 1);
			re_update_shader_block(pipeline->_re_user_data_block, RE_USER_DATA_REF, 0, pipeline->_re_user_data_block->size);
		}

		_re_refresh_framebuffer(pass._target_framebuffer);
		//glBindTexture(GL_TEXTURE_2D, pass._target_framebuffer->_fb_texture._handle);
		glBindFramebuffer(GL_FRAMEBUFFER, pass._target_framebuffer->_id);
		re_clear_color();
		glClear(GL_DEPTH_BUFFER_BIT);

		glUseProgram(pass.shader_program._program_id);
		pass._rendpass_cb(&pass, NULL);
		switch (pass.target)
		{
		case SCENE:
			re_draw_scene_recursive(root,&pass);
			break;
		case SCREEN:
			re_draw_triangles(6);
			break;
		default:
			re_draw_triangles(6);
			break;
		}



	}


}

#endif
#endif
//#include "gfx_ogl.h"
