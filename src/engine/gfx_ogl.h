#ifndef RE_GFX_H
#define RE_GFX_H


#include "realm_engine.h"
#include <glad/glad.h>
#include <stdint.h>
#include "math.h"
#include <stdlib.h>
#include<stdio.h>
#define _RE_SHADERLANG_VER_STR "#version 430 core\n\0"
vector_decl(GLint)

typedef enum re_shader_type_t
{
	RE_VERTEX_SHADER,
	RE_FRAGMENT_SHADER


} re_shader_type_t;

typedef struct re_shader_t
{
	GLuint _shader_id;
	char* name;
	re_shader_type_t type;
	char* source;
}re_shader_t;



typedef struct _re_sampler_uniform_cache
{
	vector(uint32_t) _hashes;
	vector(GLint) _locations;
	size_t _num_elements;

}_re_sampler_uniform_cache;

typedef struct re_shader_program_t
{
	GLuint _program_id;
	char* name;
	re_shader_t source[2];
	_re_sampler_uniform_cache _sampler_cache;


}re_shader_program_t;

typedef struct re_vertex_attr_desc_t
{
	re_vertex_type_t type;
	uint16_t offset;
	uint8_t index;
	re_attribute_slot attribute_slot;
}re_vertex_attr_desc_t;

typedef struct re_vertex_buffer_t
{
	GLuint _id;
	uint16_t size;

}re_vertex_buffer_t;

typedef struct re_index_buffer_t
{
	GLuint _id;
	uint16_t size;
	uint16_t num_triangles;
}re_index_buffer_t;

typedef struct re_shader_block_t
{
	GLuint _id;
	void* _buffer_map;
	uint32_t size;
	uint32_t ref_index;
	const char* name;

}re_shader_block_t;

typedef enum re_framebuffer_attachment_type
{
	RE_COLOR_ATTACHMENT = 0,
	RE_DEPTH_ATTACHMENT = 1,
	RE_STENCIL_ATTACHMENT = 2,
	RE_DEPTH_STENCIL_ATTACHMENT = RE_DEPTH_ATTACHMENT + RE_STENCIL_ATTACHMENT
}re_framebuffer_attachment_type;

vector_decl(re_framebuffer_attachment_type);

typedef enum re_framebuffer_attachment_storage_type
{
	RE_FBTEXTURE = 0,
	RE_FBRENDERBUFFER = 1

}re_framebuffer_attachment_storage_type;
typedef struct re_framebuffer_attachment_t
{
	re_framebuffer_attachment_type type;
	re_texture_t texture;
	re_framebuffer_attachment_storage_type storage_type;
}re_framebuffer_attachment_t;
vector_decl(re_framebuffer_attachment_t);
typedef struct re_framebuffer_t
{
	GLuint _id;

	vector(re_framebuffer_attachment_t) attachment;


}re_framebuffer_t;



typedef struct re_framebuffer_attachment_desc_t
{
	re_framebuffer_attachment_type type;
	re_texture_filter_func filter;
	re_framebuffer_attachment_storage_type storage_type;
	re_image_format format;


}re_framebuffer_attachment_desc_t;




typedef enum re_renderpass_type
{
	COLOR_PASS = RE_COLOR_ATTACHMENT,
	DEPTH_PASS = RE_DEPTH_ATTACHMENT,
	DEPTH_STENCIL_PASS = COLOR_PASS + DEPTH_PASS
}re_renderpass_type;
typedef enum re_renderpass_target
{
	RE_TARGET_SCENE,
	RE_TARGET_SCREEN
}re_renderpass_target;

typedef void(*on_renderpass)(struct re_renderpass_t* renderpass, void* userdata);

typedef enum re_depth_mode
{
	RE_DEPTH_ON,
	RE_DEPTH_OFF

}re_depth_mode;

typedef struct re_renderpass_desc_t
{
	re_renderpass_type type;
	re_shader_program_t* shader_program;
	re_framebuffer_t* target_framebuffer;
	on_renderpass _renderpass_cb;
	re_renderpass_target target;
	void* renderpass_cb_data;
	size_t renderpass_cb_data_size;
}re_renderpass_desc_t;

typedef struct re_renderpass_t
{
	re_framebuffer_t* _target_framebuffer;
	re_shader_program_t shader_program;
	re_user_data_layout_t _user_data_layout;
	uint8_t _user_pass;
	re_renderpass_type type;
	on_renderpass _rendpass_cb;
	void* _renderpass_cb_data;
	re_renderpass_target target;
}re_renderpass_t;

typedef struct re_gfx_pipeline_desc_t
{
	uint16_t num_attribs;
	re_vertex_attr_desc_t attributes[GL_MAX_VERTEX_ATTRIBS];

}re_gfx_pipeline_desc_t;

linked_list_decl(re_renderpass_t);
typedef struct re_renderpath_t
{
	linked_list(re_renderpass_t) _linked_list;
	re_framebuffer_t* _scene_fb;
	re_framebuffer_t* _screen_fb;
	re_framebuffer_t* _depth_stencil_fb;


}re_renderpath_t;

typedef struct re_gfx_pipeline_t
{

	uint16_t num_attribs;
	re_vertex_attr_desc_t attributes[GL_MAX_VERTEX_ATTRIBS];
	uint16_t vertex_layout_size;
	GLuint _vao;
	GLuint _vbo;
	GLuint _ibo;
	re_shader_block_t* _re_global_data_block;
	re_shader_block_t* _re_user_data_block;
	re_global_data_t* re_global_data;
	re_renderpath_t _main_renderpath;


}re_gfx_pipeline_t;

static float _screen_mesh_positions[4][3] = {
	{-1,-1,0},
	{1,-1,0},
	{1,1,0},
	{-1,1,0}
};
static float _screen_uv[4][2] = {
	{0,0},
	{1,0},
	{1,1},
	{0,1}
};

static float _screen_normal[4][3] = {
	{0,0,0},
	{0,0,0},
	{0,0,0},
	{0,0,0}
};
re_mesh_t _screen_mesh;
static uint32_t _screen_triangles[6] = { 0,1,2,2,3,0 };

re_gfx_pipeline_t _re_gfx_pipeline;
#define RE_GRAPHICS_PIPELINE &_re_gfx_pipeline
#define _ENUM_CONVERSION_FUNCTION(T, v) REALM_ENGINE_FUNC GLenum _##T##_to_glenum(T v)
//#define re_grab_screentexture RE_GRAPHICS_PIPELINE._main_renderpath._scene_fb->_fb_texture
#define re_grab_depthtexture RE_GRAPHICS_PIPELINE._main_renderpath._depth_stencil_fb->_fb_texture
#define ogl_texture_unit(unit) (GL_TEXTURE0+unit)
_ENUM_CONVERSION_FUNCTION(re_texture_filter_func, func);
_ENUM_CONVERSION_FUNCTION(re_texture_wrap_func, wrap_func);
_ENUM_CONVERSION_FUNCTION(re_image_type, type);
_ENUM_CONVERSION_FUNCTION(re_image_format, fmt);
REALM_ENGINE_FUNC re_user_data_var_types _glenum_to_userdata_type(GLenum type);
_ENUM_CONVERSION_FUNCTION(re_shader_type_t, type);
_ENUM_CONVERSION_FUNCTION(re_framebuffer_attachment_type, type);
REALM_ENGINE_FUNC re_result_t re_compile_shader(re_shader_t* sh);
REALM_ENGINE_FUNC re_result_t re_init_program(re_shader_program_t* program_data);
REALM_ENGINE_FUNC re_result_t re_set_pipeline_desc(re_gfx_pipeline_desc_t* desc);
REALM_ENGINE_FUNC re_vertex_buffer_t* re_create_vertex_buffer();
REALM_ENGINE_FUNC re_index_buffer_t* re_create_index_buffer();
REALM_ENGINE_FUNC re_result_t re_gen_texture(re_texture_t* texture);
REALM_ENGINE_FUNC re_result_t re_create_framebuffer(re_framebuffer_t* buffer);
REALM_ENGINE_FUNC re_result_t re_upload_index_data(uint32_t* triangles, uint32_t num_triangles);
REALM_ENGINE_FUNC re_result_t re_upload_mesh_data(re_mesh_t* mesh, re_transform_t* transform);
REALM_ENGINE_FUNC re_result_t re_upload_vertex_data(vec3* positions, uint16_t num_vertices);
REALM_ENGINE_FUNC GLenum _re_type_to_gltype(re_vertex_type_t type);
REALM_ENGINE_FUNC re_result_t re_bind_vbo(re_vertex_buffer_t buffer);
REALM_ENGINE_FUNC re_result_t re_bind_ibo(re_index_buffer_t buffer);
REALM_ENGINE_FUNC re_result_t re_bind_pipeline_attributes();
REALM_ENGINE_FUNC re_result_t re_query_userdata_layout(re_renderpass_t* pass, re_user_data_layout_t* layout);
REALM_ENGINE_FUNC int32_t re_get_uniform_index(re_user_data_layout_t* layout, const char* name);
REALM_ENGINE_FUNC re_result_t re_set_userdata_vector(re_user_data_layout_t* layout, const char* name, vec4 value);
REALM_ENGINE_FUNC re_result_t re_set_texture(re_shader_program_t* program, const char* name, re_texture_t* texture);
REALM_ENGINE_FUNC re_shader_block_t* re_create_shader_block(const char* block_name, void* initial_data, uint32_t initial_size);
REALM_ENGINE_FUNC re_result_t re_bind_shader_block(re_shader_block_t* block, const char* reference, uint32_t binding_point);
REALM_ENGINE_FUNC re_result_t re_update_shader_block(re_shader_block_t* block, void* data, uint32_t offset, uint32_t size);
REALM_ENGINE_FUNC re_result_t re_set_userdata_block(void* data, uint32_t size);
REALM_ENGINE_FUNC re_renderpass_t* re_create_renderpass(re_renderpass_desc_t* desc);
REALM_ENGINE_FUNC re_result_t re_use_renderpass(re_renderpass_t* pass);
//REALM_ENGINE_FUNC re_result_t _re_refresh_framebuffer(re_framebuffer_t* buffer);
REALM_ENGINE_FUNC re_result_t re_use_framebuffer(re_framebuffer_t* fb);
REALM_ENGINE_FUNC void _on_default_scene_render(re_renderpass_t* renderpass, void* userdata);
REALM_ENGINE_FUNC void _on_default_screen_render(re_renderpass_t* renderpass, void* userdata);
REALM_ENGINE_FUNC re_result_t _re_init_main_renderpath();
REALM_ENGINE_FUNC re_result_t re_init_gfx_pipeline();
REALM_ENGINE_FUNC re_result_t re_pipeline_start_draw();
REALM_ENGINE_FUNC re_result_t re_pipeline_end_draw();
REALM_ENGINE_FUNC re_result_t re_draw_triangles(uint16_t numTris);
REALM_ENGINE_FUNC re_result_t re_add_framebuffer_attachment(re_framebuffer_t* framebuffer, re_framebuffer_attachment_type attachement, re_framebuffer_attachment_desc_t* desc);
REALM_ENGINE_FUNC void re_set_bg_color(float r, float g, float b, float a, uint8_t normalize);
REALM_ENGINE_FUNC void re_clear_color();



#ifdef RE_GFX_IMPL

_ENUM_CONVERSION_FUNCTION(re_texture_filter_func, func)
{
	GLenum result;
	switch (func)
	{
	case NEAREST:
		result = GL_NEAREST;
		break;
	case LINEAR:
		result = GL_LINEAR;
		break;
	default:
		break;
	}

	return result;

}


_ENUM_CONVERSION_FUNCTION(re_texture_wrap_func, wrap_func)
{
	GLenum result;
	switch (wrap_func)
	{
	case CLAMP_TO_EDGE:
		result = GL_CLAMP_TO_EDGE;
		break;
	case CLAMP_TO_BORDER:
		result = GL_CLAMP_TO_BORDER;
		break;
	case REPEAT:
		result = GL_REPEAT;
		break;
	default:
		result = GL_REPEAT;
		break;
	}


}

_ENUM_CONVERSION_FUNCTION(re_image_type, type)
{

	GLenum result;
	switch (type)
	{
	case CUBEMAP:
		result = GL_TEXTURE_CUBE_MAP;
		break;
	case TEXTURE2D:
		result = GL_TEXTURE_2D;
		break;
	case TEXTURE3D:
		result = GL_TEXTURE_3D;
		break;
	case TEXTURE2DARRAY:
		result = GL_TEXTURE_2D_ARRAY;
		break;
	default:
		result = GL_TEXTURE_2D;
		break;
	}
	return result;

}

_ENUM_CONVERSION_FUNCTION(re_image_format, fmt)
{
	GLenum result;
	switch (fmt)
	{
	case RGB:
		return GL_RGB;
		break;
	case RGBA8:
		return GL_RGBA;
		break;
	case SRGB:
		return GL_SRGB;
		break;
	case DEPTH_STENCIL:
		return GL_DEPTH_STENCIL;
		break;
	case DEPTH:
		return GL_DEPTH_COMPONENT;
		break;
	default:
		break;
	}
}

REALM_ENGINE_FUNC GLenum _re_image_format_to_gl_format(re_image_format fmt)
{
	switch (fmt)
	{
	case RGB:
		return GL_RGB;
		break;
	case RGBA8:
		return GL_RGBA;
		break;
	case SRGB:
		return GL_RGB;
		break;
	case DEPTH_STENCIL:
		return GL_DEPTH_STENCIL;
		break;
	case DEPTH:
		return GL_DEPTH_COMPONENT;
		break;
	default:
		break;
	}
}

REALM_ENGINE_FUNC GLenum _re_image_format_to_gl_data_type(re_image_format fmt)
{
	switch (fmt)
	{
	case RGB:
		return GL_UNSIGNED_BYTE;
		break;
	case RGBA8:
		return GL_UNSIGNED_BYTE;
		break;
	case SRGB:
		return GL_UNSIGNED_BYTE;
		break;
	case DEPTH_STENCIL:
		return GL_DEPTH24_STENCIL8;
		break;
	case DEPTH:
		return GL_FLOAT;
		break;
	default:
		break;
	}
}

REALM_ENGINE_FUNC re_user_data_var_types _glenum_to_userdata_type(GLenum type)
{
	re_user_data_var_types user_type;
	switch (type)
	{
	case GL_FLOAT:
		user_type = RE_FLOAT;
		break;
	case GL_FLOAT_VEC4:
		user_type = RE_VECTOR;
		break;
	case GL_FLOAT_MAT4:
		user_type = RE_MATRIX;
		break;
	case GL_SAMPLER_2D:
		user_type = RE_TEXTURE2D;
		break;
	default:
		user_type = RE_VECTOR;
		break;
	}
	return user_type;
}


_ENUM_CONVERSION_FUNCTION(re_shader_type_t, type)
{
	GLenum result;
	switch (type)
	{
	case RE_FRAGMENT_SHADER:
		result = GL_FRAGMENT_SHADER;
		break;
	case RE_VERTEX_SHADER:
		result = GL_VERTEX_SHADER;
		break;
	default:
		result = GL_VERTEX_SHADER;
		break;
	}

	return result;
}

_ENUM_CONVERSION_FUNCTION(re_framebuffer_attachment_type, type)
{
	GLenum result;
	switch (type)
	{
	case RE_COLOR_ATTACHMENT:
		result = GL_COLOR_ATTACHMENT0;
		break;
	case RE_DEPTH_ATTACHMENT:
		result = GL_DEPTH_ATTACHMENT;
		break;
	case RE_STENCIL_ATTACHMENT:
		result = GL_STENCIL_ATTACHMENT;
		break;
	case RE_DEPTH_STENCIL_ATTACHMENT:
		result = GL_DEPTH_STENCIL_ATTACHMENT;
		break;
	default:
		break;
	}
	return result;

}


REALM_ENGINE_FUNC re_result_t re_compile_shader(re_shader_t* sh)
{
	sh->_shader_id = glCreateShader(_re_shader_type_t_to_glenum(sh->type));
	GLuint shader = sh->_shader_id;
	glShaderSource(shader, 1, (const char* const*)&sh->source, NULL);
	glCompileShader(shader);
	int status;
	glGetShaderiv(shader, GL_COMPILE_STATUS, &status);
	if (status == GL_FALSE)
	{
		int len;
		glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &len);
		char* message = (char*)malloc(len * sizeof(char));
		glGetShaderInfoLog(shader, len, &len, message);
		if (message != NULL)
		{

			re_log(RE_LOG_HIGH, "Error compiling shader %s \n %s\n", sh->name, message);
			return RE_ERROR;

		}


	}
	return RE_OK;
}



REALM_ENGINE_FUNC re_result_t re_init_program(re_shader_program_t* program_data)
{

	re_log(RE_LOG_NONE, "Linking shader program %s\n", program_data->name);

	int i;
	program_data->_program_id = glCreateProgram();
	for (i = 0; i < 2; i++)
	{
		glAttachShader(program_data->_program_id, program_data->source[i]._shader_id);
	}
	glLinkProgram(program_data->_program_id);
	for (i = 0; i < 2; i++)
	{
		glDeleteShader(program_data->source[i]._shader_id);
	}

	char result[256];
	int success;
	glGetProgramiv(program_data->_program_id, GL_LINK_STATUS, &success);
	if (!success)
	{
		glGetProgramInfoLog(program_data->_program_id, 256, NULL, result);
		re_log(RE_LOG_HIGH, "Could not link program %s\n%s\n", program_data->name, result);
		return RE_ERROR;
	}

	uint32_t num_uniforms = 0;
	glGetProgramiv(program_data->_program_id, GL_ACTIVE_UNIFORMS, &num_uniforms);
	for (i = 0; i < num_uniforms; i++)
	{
		GLenum type;
		glGetActiveUniformsiv(program_data->_program_id, 1, &i, GL_UNIFORM_TYPE, &type);
		if (type == GL_SAMPLER_2D)
		{
			GLint name_len = 0;
			glGetActiveUniformsiv(program_data->_program_id, 1, &i, GL_UNIFORM_NAME_LENGTH, &name_len);
			char name[name_len];


			glGetActiveUniformName(program_data->_program_id, i, name_len, &name_len, &name);

			GLint location = glGetUniformLocation(program_data->_program_id, name);
			_re_sampler_uniform_cache* cache = &program_data->_sampler_cache;
			uint32_t hash = re_adler32_str(name);
			vector_append(GLint, &cache->_locations, location);
			vector_append(uint32_t, &cache->_hashes, hash);

		}



	}


	return RE_OK;



}

REALM_ENGINE_FUNC re_result_t re_set_pipeline_desc(re_gfx_pipeline_desc_t* desc)
{
	memcpy(&_re_gfx_pipeline.attributes, &desc->attributes, sizeof(desc->attributes));
	_re_gfx_pipeline.num_attribs = desc->num_attribs;


}

REALM_ENGINE_FUNC re_vertex_buffer_t* re_create_vertex_buffer()
{
	re_vertex_buffer_t* buffer = (re_vertex_buffer_t*)malloc(sizeof(re_vertex_buffer_t));
	glGenBuffers(1, &buffer->_id);
	glBindBuffer(GL_ARRAY_BUFFER, buffer->_id);
	glBufferData(GL_ARRAY_BUFFER, 0, NULL, GL_STATIC_DRAW);
	glBindBuffer(GL_ARRAY_BUFFER, 0);
	return buffer;

}

REALM_ENGINE_FUNC re_index_buffer_t* re_create_index_buffer()
{
	re_index_buffer_t* buffer = (re_index_buffer_t*)malloc(sizeof(re_index_buffer_t));
	glGenBuffers(1, &buffer->_id);
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, buffer->_id);
	glBufferData(GL_ELEMENT_ARRAY_BUFFER, 0, NULL, GL_STATIC_DRAW);
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
	return buffer;
}



REALM_ENGINE_FUNC re_result_t re_gen_texture(re_texture_t* texture)
{
	GLenum wrap = _re_texture_wrap_func_to_glenum(texture->wrap);
	GLenum filter = _re_texture_filter_func_to_glenum(texture->filter);
	GLenum target = _re_image_type_to_glenum(texture->type);
	GLenum internal_format = _re_image_format_to_glenum(texture->format);
	GLenum format = _re_image_format_to_gl_format(texture->format);
	GLenum type = _re_image_format_to_gl_data_type(texture->format);
	glGenTextures(1, &texture->_handle);
	glBindTexture(target, texture->_handle);
	glTexParameteri(target, GL_TEXTURE_WRAP_S, wrap);
	glTexParameteri(target, GL_TEXTURE_WRAP_T, wrap);
	glTexParameteri(target, GL_TEXTURE_MIN_FILTER, filter);
	glTexParameteri(target, GL_TEXTURE_MAG_FILTER, filter);
	/*glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_COMPARE_FUNC, GL_LEQUAL);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_COMPARE_MODE, GL_NONE);*/
	glTexImage2D(target, 0, internal_format, texture->width, texture->height, 0, format, type, texture->data);
	glGenerateMipmap(target);
	glBindTexture(target, 0);



}

REALM_ENGINE_FUNC re_result_t re_create_framebuffer(re_framebuffer_t* buffer)
{

	if (buffer == NULL)
	{
		return RE_ERROR;
	}
	buffer->attachment = new_vector(re_framebuffer_attachment_t,2);
	glGenFramebuffers(1, &buffer->_id);
	glBindFramebuffer(GL_FRAMEBUFFER, buffer->_id);

	glBindFramebuffer(GL_FRAMEBUFFER, 0);


	return RE_OK;
}


REALM_ENGINE_FUNC re_result_t re_upload_index_data(uint32_t* triangles, uint32_t num_triangles)
{

	glBufferData(GL_ELEMENT_ARRAY_BUFFER, num_triangles * sizeof(uint32_t), triangles, GL_DYNAMIC_DRAW);
	return RE_OK;
}
REALM_ENGINE_FUNC re_result_t re_upload_mesh_data(re_mesh_t* mesh, re_transform_t* transform)
{
	re_gfx_pipeline_t* pipeline = RE_GRAPHICS_PIPELINE;
	uint16_t pos_size = sizeof(vec3) * mesh->mesh_size;
	uint16_t uv_size = sizeof(vec2) * mesh->mesh_size;
	uint16_t normal_size = sizeof(vec3) * mesh->mesh_size;
	uint16_t tangent_size = sizeof(vec3) * mesh->mesh_size;
	float mesh_data[pos_size + uv_size + normal_size + tangent_size];
	int i, j;
	vec3 positions[mesh->mesh_size];
	vec3 normals[mesh->mesh_size];
	vec3 tangents[mesh->mesh_size];
	re_apply_transform(transform, mesh, &positions, &normals, &tangents);
	//re_print(mesh);
	glBufferData(GL_ARRAY_BUFFER, pos_size + uv_size + normal_size + tangent_size, 0, GL_DYNAMIC_DRAW);
	for (i = 0; i < mesh->mesh_size; i++)
	{
		for (j = 0; j < pipeline->num_attribs; j++)
		{
			re_vertex_attr_desc_t attribute = pipeline->attributes[j];
			uint16_t attri_size = SHADER_VAR_SIZE(attribute.type);
			int dst = pipeline->vertex_layout_size * i + attribute.offset;
			switch (attribute.attribute_slot)
			{
			case RE_POSITION_ATTRIBUTE:

				glBufferSubData(GL_ARRAY_BUFFER, dst, attri_size, &positions[i]);
				break;
			case RE_TEXCOORD_ATTRIBUTE:
				glBufferSubData(GL_ARRAY_BUFFER, dst, attri_size, &mesh->texcoords.elements[i]);
				break;
			case RE_NORMAL_ATTRIBUTE:
				glBufferSubData(GL_ARRAY_BUFFER, dst, attri_size, &normals[i]);
				break;
			case RE_TANGENT_ATTRIBUTE:
				glBufferSubData(GL_ARRAY_BUFFER, dst, attri_size, &tangents[i]);
			default:
				break;
			}
			//dst += attri_size;
		}
	}



	re_upload_index_data(mesh->triangles.elements, mesh->triangles.count);

	return RE_OK;

}
REALM_ENGINE_FUNC re_result_t re_upload_vertex_data(vec3* positions, uint16_t num_vertices)
{
	uint32_t size = num_vertices * sizeof(vec3);
	glBufferData(GL_ARRAY_BUFFER, size, positions, GL_DYNAMIC_DRAW);
	return RE_OK;


}



REALM_ENGINE_FUNC GLenum _re_type_to_gltype(re_vertex_type_t type)
{
	GLenum result;
	switch (SHADER_VAR_TYPE(type))
	{
	case 1:
		result = GL_FLOAT;
		break;
	case 0xF:
		result = GL_SAMPLER_2D;
	default:
		break;
	}
	return result;
}





REALM_ENGINE_FUNC re_result_t re_bind_vbo(re_vertex_buffer_t buffer)
{
	glBindBuffer(GL_ARRAY_BUFFER, buffer._id);
	return RE_OK;

}

REALM_ENGINE_FUNC re_result_t re_bind_ibo(re_index_buffer_t buffer)
{
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, buffer._id);
	return RE_OK;
}

REALM_ENGINE_FUNC re_result_t re_bind_pipeline_attributes()
{
	re_gfx_pipeline_t* pipeline = RE_GRAPHICS_PIPELINE;
	pipeline->vertex_layout_size = 0;
	uint32_t stride = 0;
	int i;
	for (i = 0; i < pipeline->num_attribs; i++)
	{
		re_vertex_attr_desc_t attribute = pipeline->attributes[i];
		GLenum type = _re_type_to_gltype(attribute.type);
		glEnableVertexAttribArray(attribute.index);
		glVertexAttribPointer(attribute.index, SHADER_VAR_ELEMENTS(attribute.type), type, GL_FALSE, 11 * sizeof(float), (void*)attribute.offset);
		pipeline->vertex_layout_size += SHADER_VAR_SIZE(attribute.type);
	}
	return RE_OK;
}







REALM_ENGINE_FUNC re_result_t re_query_userdata_layout(re_renderpass_t* pass, re_user_data_layout_t* layout)
{
	re_gfx_pipeline_t* pipeline = RE_GRAPHICS_PIPELINE;
	re_shader_block_t* block = pipeline->_re_user_data_block;
	re_shader_program_t program = pass->shader_program;
	block->ref_index = glGetUniformBlockIndex(program._program_id, RE_USER_DATA_REF);;
	GLuint block_index = block->ref_index;
	int32_t num_uniforms = 0;
	glGetActiveUniformBlockiv(program._program_id, block_index, GL_UNIFORM_BLOCK_ACTIVE_UNIFORMS, &num_uniforms);
	GLint* block_uniform_indices = (int32_t*)(malloc(sizeof(GLint) * num_uniforms));
	glGetActiveUniformBlockiv(program._program_id, block_index, GL_UNIFORM_BLOCK_ACTIVE_UNIFORM_INDICES, block_uniform_indices);
	int32_t name_length[num_uniforms];
	layout->var_offsets = (int32_t*)malloc(sizeof(uint32_t) * num_uniforms);
	layout->num_vars = num_uniforms;
	layout->var_types = (re_user_data_var_types*)malloc(sizeof(re_user_data_var_types) * num_uniforms);
	layout->var_names = (char**)malloc(num_uniforms * 64);
	layout->_hashes = (uint32_t*)malloc(num_uniforms * sizeof(uint32_t));
	layout->block_size = 0;
	int32_t* types = (int32_t*)malloc(sizeof(int32_t) * num_uniforms);
	glGetActiveUniformsiv(program._program_id, num_uniforms, (GLuint*)block_uniform_indices, GL_UNIFORM_NAME_LENGTH, name_length);
	glGetActiveUniformsiv(program._program_id, num_uniforms, (GLuint*)block_uniform_indices, GL_UNIFORM_OFFSET, layout->var_offsets);
	glGetActiveUniformsiv(program._program_id, num_uniforms, (GLuint*)block_uniform_indices, GL_UNIFORM_TYPE, types);
	int i;
	for (i = 0; i < num_uniforms; i++)
	{
		char* name = (char*)malloc(sizeof(char) * name_length[0]);
		glGetActiveUniformName(program._program_id, block_uniform_indices[i], name_length[0], NULL, name);

		layout->var_names[i] = name;
		layout->var_types[i] = _glenum_to_userdata_type(types[i]);
		layout->_hashes[i] = re_adler32_str(name);
		int elements = SHADER_VAR_ELEMENTS(layout->var_types[i]);
		int byte_size = SHADER_VAR_BYTES(layout->var_types[i]);
		layout->block_size += SHADER_VAR_SIZE(layout->var_types[i]);

		block->size = layout->block_size;
		printf("\n%s", name);


	}
	//free(name_length);
	free(types);
	free(block_uniform_indices);

	return RE_OK;

}

REALM_ENGINE_FUNC int32_t re_get_uniform_index(re_user_data_layout_t* layout, const char* name)
{
	int i;
	for (i = 0; i < layout->num_vars; i++)
	{
		if (strcmp(layout->var_names[i], name) == 0)
		{
			return i;
		}

	}
	return -1;


}

REALM_ENGINE_FUNC re_result_t re_set_userdata_vector(re_user_data_layout_t* layout, const char* name, vec4 value)
{
	int32_t idx = re_get_uniform_index(layout, name);
	if (idx >= 0)
	{
		uint32_t offset = layout->var_offsets[idx];
		glBufferSubData(GL_UNIFORM_BUFFER, offset, sizeof(vec4), &value);
	}
	return RE_OK;

}



REALM_ENGINE_FUNC GLint _re_lookup_sampler_locations(re_shader_program_t* program, const char* name)
{
	_re_sampler_uniform_cache cache = program->_sampler_cache;
	GLint result = -1;
	uint32_t hash = re_adler32_str(name);
	int i;
	for (i = 0; i < cache._hashes.count; i++)
	{
		if (hash == cache._hashes.elements[i])
		{
			result = cache._locations.elements[i];
		}
	}
	if (result < 0)
	{
		result = glGetUniformLocation(program->_program_id, name);

		vector_append(uint32_t, &cache._hashes, hash);
		vector_append(GLint, &cache._locations, result);
	}
	return result;


}

REALM_ENGINE_FUNC re_result_t re_set_texture(re_shader_program_t* program, const char* name, re_texture_t* texture)
{
	GLint location = _re_lookup_sampler_locations(program, name);
	glBindTextureUnit(location, texture->_handle);
}







REALM_ENGINE_FUNC re_shader_block_t* re_create_shader_block(const char* block_name, void* initial_data, uint32_t initial_size)
{
	re_shader_block_t* block = (re_shader_block_t*)malloc(sizeof(re_shader_block_t));


	block->name = block_name;
	glGenBuffers(1, &block->_id);
	glBindBuffer(GL_UNIFORM_BUFFER, block->_id);
	glBufferData(GL_UNIFORM_BUFFER, initial_size, initial_data, GL_DYNAMIC_DRAW);

	return block;

}

REALM_ENGINE_FUNC re_result_t re_bind_shader_block(re_shader_block_t* block, const char* reference, uint32_t binding_point)
{
	glBindBuffer(GL_UNIFORM_BUFFER, block->_id);

	glBindBufferBase(GL_UNIFORM_BUFFER, binding_point, block->_id);

	return RE_OK;
}



REALM_ENGINE_FUNC re_result_t re_update_shader_block(re_shader_block_t* block, void* data, uint32_t offset, uint32_t size)
{

	glBufferData(GL_UNIFORM_BUFFER, size, data, GL_DYNAMIC_DRAW);
	block->size = size;
	return RE_OK;
}

REALM_ENGINE_FUNC re_result_t re_set_userdata_block(void* data, uint32_t size)
{
	re_gfx_pipeline_t* pipeline = RE_GRAPHICS_PIPELINE;
	re_update_shader_block(pipeline->_re_user_data_block, data, 0, size);
	return RE_OK;
}


REALM_ENGINE_FUNC re_renderpass_t* re_create_renderpass(re_renderpass_desc_t* desc)
{
	re_gfx_pipeline_t* pipeline = RE_GRAPHICS_PIPELINE;
	re_renderpass_t* pass = (re_renderpass_t*)(malloc(sizeof(re_renderpass_t)));


	memcpy(&pass->shader_program, desc->shader_program, sizeof(re_shader_program_t));
	glUseProgram(pass->shader_program._program_id);
	re_query_userdata_layout(pass, &pass->_user_data_layout);
	pass->type = desc->type;
	pass->_target_framebuffer = desc->target_framebuffer;
	pass->_rendpass_cb = desc->_renderpass_cb;
	glUseProgram(0);
	pass->_user_pass = 1;
	pass->target = desc->target;
	pass->_renderpass_cb_data = malloc(desc->renderpass_cb_data_size);
	if (desc->renderpass_cb_data_size > 0)
	{
		memcpy(&pass->_renderpass_cb_data, &desc->renderpass_cb_data, desc->renderpass_cb_data_size);
	}
	return pass;

}

REALM_ENGINE_FUNC re_result_t re_use_renderpass(re_renderpass_t* pass)
{
	re_gfx_pipeline_t* pipeline = RE_GRAPHICS_PIPELINE;
	glUseProgram(pass->shader_program._program_id);
	int width = 0;
	int height = 0;
	re_context_size(&width, &height);
	re_use_framebuffer(pass->_target_framebuffer);

	return RE_OK;

}

/*
REALM_ENGINE_FUNC re_result_t _re_refresh_framebuffer(re_framebuffer_t* buffer)
{
	re_texture_t texture = buffer->_fb_texture;
	GLenum wrap = _re_texture_wrap_func_to_glenum(texture.wrap);
	GLenum filter = _re_texture_filter_func_to_glenum(texture.filter);
	GLenum target = _re_image_type_to_glenum(texture.type);
	GLenum internal_format = _re_image_format_to_glenum(texture.format);
	GLenum format = _re_image_format_to_gl_format(texture.format);
	GLenum type = _re_image_format_to_gl_data_type(texture.format);
	glBindTexture(GL_TEXTURE_2D, texture._handle);
	int width = 0;
	int height = 0;
	re_context_size(&width, &height);
	glTexImage2D(GL_TEXTURE_2D, 0, internal_format, width, height, 0, format, type, 0);
	glBindTexture(GL_TEXTURE_2D, 0);
	return RE_OK;


}
*/


REALM_ENGINE_FUNC re_result_t re_update_vp(mat4x4 matrix)
{

	re_gfx_pipeline_t* pipeline = RE_GRAPHICS_PIPELINE;
	memcpy(&pipeline->re_global_data->view_projection, &matrix, sizeof(mat4x4));


	return RE_OK;
}


REALM_ENGINE_FUNC re_result_t re_use_framebuffer(re_framebuffer_t* fb)
{
	glBindFramebuffer(GL_FRAMEBUFFER, fb->_id);
}

REALM_ENGINE_FUNC void _on_default_scene_render(re_renderpass_t* renderpass, void* userdata)
{


	//re_set_userdata_vector(&renderpass->_user_data_layout, "color", new_vec4(1.0, 1.0, 1.0, 0.0));
	//re_set_texture(&renderpass->shader_program, "depthTexture", re_grab_depthtexture);
	//glEnable(GL_DEPTH_TEST);
}



REALM_ENGINE_FUNC void _on_default_screen_render(re_renderpass_t* renderpass, void* userdata)
{
	//glDisable(GL_DEPTH_TEST);
	re_upload_mesh_data(&_screen_mesh, &new_transform);
	re_texture_t* texture = &_re_gfx_pipeline._main_renderpath._scene_fb->attachment.elements[0].texture;

	re_set_texture(&renderpass->shader_program, "screenTexture", texture);
}

REALM_ENGINE_FUNC void _on_default_depth_render(re_renderpass_t* renderpass, void* userdata)
{
	/*glEnable(GL_DEPTH_TEST);
	glClear(GL_DEPTH_BUFFER_BIT);*/
	glEnable(GL_DEPTH_TEST);
}


REALM_ENGINE_FUNC re_result_t re_load_shaders(re_shader_program_t* program, const char* frag_path, const char* vert_path)
{
	{
		long fragment_size = re_get_file_size(frag_path);
		long vertex_size = re_get_file_size(vert_path);
		size_t new_vertex_size = 0;
		size_t new_fragment_size = 0;
		char* processed_fragment;
		char* processed_vertex;
		char fragment[fragment_size + 1];
		char vertex[vertex_size + 1];
		memset(fragment, 0, sizeof(fragment));
		memset(vertex, 0, sizeof(vertex));
		re_read_text(frag_path, fragment, fragment_size);
		re_read_text(vert_path, vertex, vertex_size);
		processed_vertex = re_preprocess_shader(vertex, vertex_size, &new_vertex_size);
		processed_fragment = re_preprocess_shader(fragment, fragment_size, &new_fragment_size);

		program->source[0] = (re_shader_t){ .name = "Vertex",.source = processed_vertex,.type = RE_VERTEX_SHADER };
		program->source[1] = (re_shader_t){ .name = "Fragment",.source = processed_fragment,.type = RE_FRAGMENT_SHADER };
		re_compile_shader(&program->source[0]);
		re_compile_shader(&program->source[1]);

		free(processed_fragment);
		free(processed_vertex);
	}


	GLint max_tex_units = 0;
	glGetIntegerv(GL_MAX_TEXTURE_IMAGE_UNITS, &max_tex_units);
	program->_sampler_cache._hashes = new_vector(uint32_t, max_tex_units);
	program->_sampler_cache._locations = new_vector(GLint, max_tex_units);
	re_init_program(program);
	return RE_OK;

}

REALM_ENGINE_FUNC re_result_t re_add_framebuffer_attachment(re_framebuffer_t* framebuffer, re_framebuffer_attachment_type attachmentType, re_framebuffer_attachment_desc_t* desc)

{
	glBindFramebuffer(GL_FRAMEBUFFER, framebuffer->_id);
	
	GLenum type = _re_framebuffer_attachment_type_to_glenum(desc->type);
	
	re_framebuffer_attachment_t* attachment = (re_framebuffer_attachment_t*)malloc(sizeof(re_framebuffer_attachment_t));
	attachment->type = desc->type;
	
	int32_t width = 0;
	int32_t height = 0;
	re_context_size(&width, &height);
	if (desc->storage_type == RE_FBTEXTURE)
	{
		
		attachment->texture.wrap = REPEAT;
		attachment->texture.filter = desc->filter;
		attachment->texture.format = desc->format;
		attachment->texture.type = TEXTURE2D;
		attachment->texture.width = width;
		attachment->texture.height = height;
		attachment->texture.data = 0;
		
		re_gen_texture(&attachment->texture);
		GLenum imageType = _re_image_type_to_glenum(attachment->texture.type);
		glBindTexture(GL_TEXTURE_2D, attachment->texture._handle);
		glFramebufferTexture2D(GL_FRAMEBUFFER, type, imageType, attachment->texture._handle, 0);
		glBindTexture(GL_TEXTURE_2D, 0);

	}
	else
	{
		uint32_t rbo;
		glGenRenderbuffers(1, &rbo);
		glBindRenderbuffer(GL_RENDERBUFFER, rbo);

		glRenderbufferStorage(GL_RENDERBUFFER, _re_image_format_to_glenum(desc->format), width, height);
		glBindRenderbuffer(GL_RENDERBUFFER, 0);
		glFramebufferRenderbuffer(GL_FRAMEBUFFER, type, GL_RENDERBUFFER, rbo);
	}

	vector_append(re_framebuffer_attachment_t, &framebuffer->attachment, *attachment);
	glBindFramebuffer(GL_FRAMEBUFFER, 0);
	return RE_OK;




}

REALM_ENGINE_FUNC re_result_t _re_init_main_renderpath()
{
	re_gfx_pipeline_t* pipeline = RE_GRAPHICS_PIPELINE;
	re_shader_program_t screen_shader;
	re_shader_program_t scene_shader;
	re_shader_program_t depth_shader;
	re_framebuffer_t* framebuffers = (re_framebuffer_t*)malloc(sizeof(re_framebuffer_t) * 2);
	screen_shader = (re_shader_program_t){
		.name = "Screen shader",

	};
	re_load_shaders(&screen_shader, "./resources/screen_shader_frag.glsl", "./resources/screen_shader_vert.glsl");
	/*
	re_load_shaders(&depth_shader, "./resources/depth_shader_frag.glsl", "./resources/depth_shader_vert.glsl");
	*/
	scene_shader = (re_shader_program_t){
			.name = "Scene shader",
	};


	re_load_shaders(&scene_shader, "./resources/scene_shader_frag.glsl", "./resources/scene_shader_vert.glsl");

	re_result_t result = re_create_framebuffer(&framebuffers[0]);
	re_add_framebuffer_attachment(&framebuffers[0], RE_COLOR_ATTACHMENT, &(re_framebuffer_attachment_desc_t)
	{
			.filter = LINEAR,
			.format = RGB,
			.type = RE_COLOR_ATTACHMENT,
			.storage_type = RE_FBTEXTURE
	});
	re_add_framebuffer_attachment(&framebuffers[0], RE_DEPTH_ATTACHMENT, &(re_framebuffer_attachment_desc_t)
	{
			.filter = LINEAR,
			.format = DEPTH_STENCIL,
			.type = RE_DEPTH_STENCIL_ATTACHMENT,
			.storage_type = RE_FBRENDERBUFFER
	});
	//result = re_create_framebuffer(&framebuffers[1]);
	pipeline->_main_renderpath._scene_fb = &framebuffers[0];
	pipeline->_main_renderpath._screen_fb = &framebuffers[1];
	memset(pipeline->_main_renderpath._screen_fb, 0, sizeof(re_framebuffer_t));

	re_renderpass_desc_t scene_shader_desc = (re_renderpass_desc_t){
		.shader_program = &scene_shader,
		.type = COLOR_PASS,
		.target_framebuffer = pipeline->_main_renderpath._scene_fb,
		._renderpass_cb = &_on_default_scene_render ,
		.target = RE_TARGET_SCENE,
		.renderpass_cb_data_size = 0
	};
	re_texture_t* scene_texture =&framebuffers[0].attachment.elements[0].texture;
	re_renderpass_desc_t screen_shader_desc = (re_renderpass_desc_t){
		.shader_program = &screen_shader,.type = COLOR_PASS,
		.target_framebuffer = pipeline->_main_renderpath._screen_fb,
		._renderpass_cb = &_on_default_screen_render ,
		.target = RE_TARGET_SCREEN,

	};
	re_renderpass_t* scene_pass = re_create_renderpass(&scene_shader_desc);
	re_renderpass_t* screen_pass = re_create_renderpass(&screen_shader_desc);
	screen_pass->_user_pass = 0;
	scene_pass->_user_pass = 1;
	linked_list_append(re_renderpass_t, &pipeline->_main_renderpath._linked_list, *scene_pass);
	linked_list_append(re_renderpass_t, &pipeline->_main_renderpath._linked_list, *screen_pass);
}

REALM_ENGINE_FUNC re_result_t re_init_gfx_pipeline()
{
	re_log(RE_LOG_NONE, "Creating graphics pipeline\n");
	re_gfx_pipeline_t* pipeline = RE_GRAPHICS_PIPELINE;
	glGenVertexArrays(1, &pipeline->_vao);

	glBindVertexArray(pipeline->_vao);

	glGenBuffers(1, &pipeline->_vbo);
	glGenBuffers(1, &pipeline->_ibo);

	glBindBuffer(GL_ARRAY_BUFFER, pipeline->_vbo);
	re_bind_pipeline_attributes();


	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, pipeline->_ibo);


	glBindVertexArray(0);
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
	glBindBuffer(GL_ARRAY_BUFFER, 0);

	pipeline->_re_global_data_block = re_create_shader_block(RE_GLOBAL_DATA_REF, 0, 0);
	pipeline->re_global_data = (re_global_data_t*)malloc(sizeof(re_global_data_t));
	memset(pipeline->re_global_data, 0, sizeof(re_global_data_t));

	glBindBuffer(GL_UNIFORM_BUFFER, 0);
	pipeline->_re_user_data_block = re_create_shader_block(RE_USER_DATA_REF, 0, 0);
	glBindBuffer(GL_UNIFORM_BUFFER, 0);
	_re_init_main_renderpath();
	re_fill_mesh(&_screen_mesh, (vec3*)_screen_mesh_positions, (vec3*)_screen_normal, (vec3*)_screen_uv, 4);
	re_set_mesh_triangles(&_screen_mesh, _screen_triangles, 6);
	glEnable(GL_DEPTH_TEST);
	return RE_OK;

}

REALM_ENGINE_FUNC re_result_t re_pipeline_start_draw()
{

	re_gfx_pipeline_t* pipeline = RE_GRAPHICS_PIPELINE;
	//glUseProgram(pipeline->program._program_id);
	glBindVertexArray(pipeline->_vao);
	glBindBuffer(GL_ARRAY_BUFFER, pipeline->_vbo);

	//glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, pipeline->_ibo);

	uint32_t size = sizeof(re_global_data_t);

	re_bind_shader_block(pipeline->_re_global_data_block, RE_GLOBAL_DATA_REF, 0);
	re_update_shader_block(pipeline->_re_global_data_block, pipeline->re_global_data, 0, size);
	//re_use_renderpass(pipeline->_screen_pass);
	/*re_bind_shader_block(pipeline->_re_user_data_block, RE_USER_DATA_REF, 1);
	re_update_shader_block(pipeline->_re_user_data_block, RE_USER_DATA_REF, 0, pipeline->_re_user_data_block->size);*/
	//re_update_shader_block(pipeline->_re_global_data_block, &new_vec4(1.0, 1.0, 1.0, 1.0), 0, sizeof(vec4));
	return RE_OK;

}


REALM_ENGINE_FUNC re_result_t re_pipeline_end_draw()
{
	re_gfx_pipeline_t* pipeline = RE_GRAPHICS_PIPELINE;
	glBufferData(GL_ARRAY_BUFFER, 0, NULL, GL_STATIC_DRAW);
	glBufferData(GL_ELEMENT_ARRAY_BUFFER, 0, NULL, GL_STATIC_DRAW);
	glBindVertexArray(0);
	glUseProgram(0);
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
	glBindBuffer(GL_ARRAY_BUFFER, 0);
	glBindBuffer(GL_UNIFORM_BUFFER, 0);
	//glDeleteFramebuffers(1, &pipeline->_screen_pass->_target_framebuffer->_id);
	return RE_OK;
}

REALM_ENGINE_FUNC re_result_t re_draw_triangles(uint16_t numTris)
{
	glDrawElements(GL_TRIANGLES, numTris, GL_UNSIGNED_INT, NULL);
	return RE_OK;
}

REALM_ENGINE_FUNC void re_set_bg_color(float r, float g, float b, float a, uint8_t normalize)
{
	if (normalize)
	{
		r = r / 255.0f;
		g = g / 255.0f;
		b = b / 255.0f;
		a = a / 255.0f;
	}

	glClearColor(r, g, b, a);


}

REALM_ENGINE_FUNC void re_clear_color()
{
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);



}





#endif
#endif // !GFX_IMPL