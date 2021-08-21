#ifndef RE_GFX_H
#define RE_GFX_H


#include "realm_engine.h"
#include <glad/glad.h>
#include <stdint.h>
#include "math.h"
#include <stdlib.h>
#include<stdio.h>


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

typedef struct re_shader_program_t
{
	GLuint _program_id;
	char* name;
	re_shader_t source[2];


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
	const char* name

}re_shader_block_t;

typedef enum re_framebuffer_attachment
{
	RE_COLOR_ATTACHMENT = 0,
	RE_DEPTH_ATTACHMENT = 1,
	RE_STENCIL_ATTACHMENT = 2,
	RE_DEPTH_STENCIL_ATTACHMENT = RE_DEPTH_ATTACHMENT + RE_STENCIL_ATTACHMENT
}re_framebuffer_attachment;



typedef struct re_framebuffer_t
{
	GLuint _id;

	re_framebuffer_attachment attachment;
	re_texture_t _fb_texture;

}re_framebuffer_t;


typedef struct re_framebuffer_desc_t
{
	re_framebuffer_attachment attachment;
	re_texture_filter_func filter;
	re_image_format format;

}re_framebuffer_desc_t;


typedef enum re_renderpass_type
{
	COLOR_PASS = RE_COLOR_ATTACHMENT,
	DEPTH_PASS = RE_DEPTH_ATTACHMENT,
	DEPTH_STENCIL_PASS = COLOR_PASS + DEPTH_PASS
}re_renderpass_type;
typedef enum re_renderpass_target
{
	SCENE,
	SCREEN
}re_renderpass_target;

typedef void(*on_renderpass)(struct re_renderpass_t* renderpass, void* userdata) ;
typedef struct re_renderpass_desc_t
{
	re_renderpass_type type;
	re_shader_program_t* shader_program;
	re_framebuffer_t* target_framebuffer;
	on_renderpass _renderpass_cb;
	re_renderpass_target target;
}re_renderpass_desc_t;

typedef struct re_renderpass_t
{
	re_framebuffer_t* _target_framebuffer;
	re_shader_program_t shader_program;
	re_user_data_layout_t _user_data_layout;
	uint8_t _user_pass;
	re_renderpass_type type;
	on_renderpass _rendpass_cb;
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
re_mesh_t _screen_mesh;
static uint32_t _screen_triangles[6] = { 0,1,2,2,3,0 };

re_gfx_pipeline_t _re_gfx_pipeline;
#define RE_GRAPHICS_PIPELINE &_re_gfx_pipeline
#define _ENUM_CONVERSION_FUNCTION(T, v) REALM_ENGINE_FUNC GLenum _##T##_to_glenum(T v)
#define re_grab_screentexture RE_GRAPHICS_PIPELINE._main_renderpath._scene_fb->_fb_texture
_ENUM_CONVERSION_FUNCTION(re_texture_filter_func, func);
_ENUM_CONVERSION_FUNCTION(re_texture_wrap_func, wrap_func);
_ENUM_CONVERSION_FUNCTION(re_image_type, type);
_ENUM_CONVERSION_FUNCTION(re_image_format, fmt);
REALM_ENGINE_FUNC re_user_data_var_types _glenum_to_userdata_type(GLenum type);
_ENUM_CONVERSION_FUNCTION(re_shader_type_t, type);
_ENUM_CONVERSION_FUNCTION(re_framebuffer_attachment, type);
REALM_ENGINE_FUNC re_result_t re_compile_shader(re_shader_t* sh);
REALM_ENGINE_FUNC re_result_t re_init_program(re_shader_program_t* program_data);
REALM_ENGINE_FUNC re_result_t re_set_pipeline_desc(re_gfx_pipeline_desc_t* desc);
REALM_ENGINE_FUNC re_vertex_buffer_t* re_create_vertex_buffer();
REALM_ENGINE_FUNC re_index_buffer_t* re_create_index_buffer();
REALM_ENGINE_FUNC re_result_t re_gen_texture(re_texture_t* texture);
REALM_ENGINE_FUNC re_framebuffer_t* re_create_framebuffer(re_framebuffer_desc_t* desc);
REALM_ENGINE_FUNC re_result_t re_init_gfx();
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
REALM_ENGINE_FUNC re_result_t re_set_texture(re_shader_program_t program, const char* name, re_texture_t* texture);
REALM_ENGINE_FUNC re_shader_block_t* re_create_shader_block(const char* block_name, void* initial_data, uint32_t initial_size);
REALM_ENGINE_FUNC re_result_t re_bind_shader_block(re_shader_block_t* block, const char* reference, uint32_t binding_point);
REALM_ENGINE_FUNC re_result_t re_update_shader_block(re_shader_block_t* block, void* data, uint32_t offset, uint32_t size);
REALM_ENGINE_FUNC re_result_t re_set_userdata_block(void* data, uint32_t size);
REALM_ENGINE_FUNC re_renderpass_t* re_create_renderpass(re_renderpass_desc_t* desc);
REALM_ENGINE_FUNC re_result_t re_use_renderpass(re_renderpass_t* pass);
REALM_ENGINE_FUNC re_result_t _re_refresh_framebuffer(re_framebuffer_t* buffer);
REALM_ENGINE_FUNC re_result_t re_update_vp(mat4x4 matrix);
REALM_ENGINE_FUNC re_result_t re_use_framebuffer(re_framebuffer_t* fb);
REALM_ENGINE_FUNC void _on_default_scene_render(re_renderpass_t* renderpass, void* userdata);
REALM_ENGINE_FUNC void _on_default_screen_render(re_renderpass_t* renderpass, void* userdata);
REALM_ENGINE_FUNC re_result_t _re_init_main_renderpath();
REALM_ENGINE_FUNC re_result_t re_init_gfx_pipeline();
REALM_ENGINE_FUNC re_result_t re_pipeline_start_draw();
REALM_ENGINE_FUNC re_result_t re_pipeline_end_draw();
REALM_ENGINE_FUNC re_result_t re_draw_triangles(uint16_t numTris);
REALM_ENGINE_FUNC void re_set_bg_color(float r, float g, float b, float a, uint8_t normalize);
REALM_ENGINE_FUNC void re_clear_color();
REALM_ENGINE_FUNC re_result_t re_render_scene(re_actor_t* root);
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
	case RGBA8:
		return GL_RGB;
		break;
	case SRGB:
		return GL_SRGB;
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

_ENUM_CONVERSION_FUNCTION(re_framebuffer_attachment, type)
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

			printf("Error compiling shader \n %s\n", message);
			return RE_ERROR;

		}


	}
	return RE_OK;
}



REALM_ENGINE_FUNC re_result_t re_init_program(re_shader_program_t* program_data)
{

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
		printf("%s\n", result);
		return RE_ERROR;
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
	glGenTextures(1, &texture->_handle);
	glBindTexture(target, texture->_handle);
	glTexParameteri(target, GL_TEXTURE_WRAP_S, wrap);
	glTexParameteri(target, GL_TEXTURE_WRAP_T, wrap);
	glTexParameteri(target, GL_TEXTURE_MIN_FILTER, filter);
	glTexParameteri(target, GL_TEXTURE_MAG_FILTER, filter);
	glTexImage2D(target, 0, GL_RGB, texture->width, texture->height, 0, GL_RGB, GL_UNSIGNED_BYTE, texture->data);
	glGenerateMipmap(target);
	glBindTexture(target, 0);



}

REALM_ENGINE_FUNC re_framebuffer_t* re_create_framebuffer(re_framebuffer_desc_t* desc)
{
	re_framebuffer_t* buffer = (re_framebuffer_t*)malloc(sizeof(re_framebuffer_t));
	glGenFramebuffers(1, &buffer->_id);
	glBindFramebuffer(GL_FRAMEBUFFER, buffer->_id);
	buffer->attachment = desc->attachment;
	buffer->_fb_texture.wrap = REPEAT;
	buffer->_fb_texture.filter = desc->filter;
	buffer->_fb_texture.format = desc->format;
	buffer->_fb_texture.type = TEXTURE2D;
	buffer->_fb_texture.width = 0;
	buffer->_fb_texture.height = 0;
	buffer->_fb_texture.data = 0;
	re_gen_texture(&buffer->_fb_texture);
	GLenum attachement = _re_framebuffer_attachment_to_glenum(buffer->attachment);
	GLenum type = _re_image_type_to_glenum(buffer->_fb_texture.type);

	glFramebufferTexture2D(GL_FRAMEBUFFER, attachement, type, buffer->_fb_texture._handle, 0);
	glBindFramebuffer(GL_FRAMEBUFFER, 0);

	return buffer;
}

REALM_ENGINE_FUNC re_result_t re_init_gfx()
{
	gladLoadGLLoader((GLADloadproc)glfwGetProcAddress);
	glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 4);
	glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 5);
	glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);
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
	float mesh_data[pos_size + uv_size];
	int i, j;
	vec3* positions = re_apply_transform(*transform, mesh);
	glBufferData(GL_ARRAY_BUFFER, pos_size + uv_size, 0, GL_DYNAMIC_DRAW);
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
				memcpy(&mesh_data[dst], &positions[i], attri_size);
				glBufferSubData(GL_ARRAY_BUFFER, dst, attri_size, &positions[i]);
				break;
			case RE_TEXCOORD_ATTRIBUTE:
				glBufferSubData(GL_ARRAY_BUFFER, dst, attri_size, &mesh->texcoords[i]);
				break;
			default:
				break;
			}
			//dst += attri_size;
		}
	}



	re_upload_index_data(mesh->triangles, 6);
	free(positions);

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
		glVertexAttribPointer(attribute.index, SHADER_VAR_ELEMENTS(attribute.type), type, GL_FALSE, 5 * sizeof(float), (void*)attribute.offset);
		pipeline->vertex_layout_size += SHADER_VAR_SIZE(attribute.type);
	}
	return RE_OK;
}







REALM_ENGINE_FUNC re_result_t re_query_userdata_layout( re_renderpass_t* pass, re_user_data_layout_t* layout)
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

REALM_ENGINE_FUNC re_result_t re_set_texture(re_shader_program_t program, const char* name, re_texture_t* texture)
{
	uint32_t location = glGetUniformLocation(program._program_id, name);
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

REALM_ENGINE_FUNC re_result_t re_set_userdata_block( void* data, uint32_t size)
{
	re_gfx_pipeline_t* pipeline = RE_GRAPHICS_PIPELINE;
	re_update_shader_block(pipeline->_re_user_data_block, data, 0, size);
	return RE_OK;
}


REALM_ENGINE_FUNC re_renderpass_t* re_create_renderpass( re_renderpass_desc_t* desc)
{
	re_gfx_pipeline_t* pipeline = RE_GRAPHICS_PIPELINE;
	re_renderpass_t* pass = (re_renderpass_t*)(malloc(sizeof(re_renderpass_t)));
	

	memcpy(&pass->shader_program, desc->shader_program, sizeof(re_shader_program_t));
	glUseProgram(pass->shader_program._program_id);
	re_query_userdata_layout( pass, &pass->_user_data_layout);
	pass->type = desc->type;
	pass->_target_framebuffer = desc->target_framebuffer;
	pass->_rendpass_cb = desc->_renderpass_cb;
	glUseProgram(0);
	pass->_user_pass = 1;
	pass->target = desc->target;
	return pass;

}

REALM_ENGINE_FUNC re_result_t re_use_renderpass( re_renderpass_t* pass)
{
	re_gfx_pipeline_t* pipeline = RE_GRAPHICS_PIPELINE;
	glUseProgram(pass->shader_program._program_id);
	int width = 0;
	int height = 0;
	re_context_size(&width, &height);
	re_use_framebuffer(pass->_target_framebuffer);
	
	return RE_OK;

}


REALM_ENGINE_FUNC re_result_t _re_refresh_framebuffer(re_framebuffer_t* buffer)
{
	re_texture_t texture = buffer->_fb_texture;
	GLenum wrap = _re_texture_wrap_func_to_glenum(texture.wrap);
	GLenum filter = _re_texture_filter_func_to_glenum(texture.filter);
	GLenum target = _re_image_type_to_glenum(texture.type);
	glBindTexture(GL_TEXTURE_2D,texture._handle);
	int width = 0;
	int height = 0;
	re_context_size(&width, &height);
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, width, height, 0, GL_RGB, GL_UNSIGNED_BYTE, 0);
	glBindTexture(GL_TEXTURE_2D, 0);
	return RE_OK;


}



REALM_ENGINE_FUNC re_result_t re_update_vp( mat4x4 matrix)
{

	re_gfx_pipeline_t* pipeline = RE_GRAPHICS_PIPELINE;
	memcpy(pipeline->re_global_data, &matrix, sizeof(mat4x4) * 3);


	return RE_OK;
}

REALM_ENGINE_FUNC re_result_t re_use_framebuffer(re_framebuffer_t* fb)
{
	glBindFramebuffer(GL_FRAMEBUFFER, fb->_id);
}

REALM_ENGINE_FUNC void _on_default_scene_render(re_renderpass_t* renderpass, void* userdata)
{
	re_set_userdata_vector(&renderpass->_user_data_layout, "color", new_vec4(1.0, 1.0, 1.0, 0.0));


}



REALM_ENGINE_FUNC void _on_default_screen_render(re_renderpass_t* renderpass, void* userdata)
{
	re_upload_mesh_data(&_screen_mesh, &new_transform);
	re_set_texture(renderpass->shader_program, "screenTexture", re_grab_screentexture);
}


REALM_ENGINE_FUNC re_result_t _re_init_main_renderpath()
{
	re_gfx_pipeline_t* pipeline = RE_GRAPHICS_PIPELINE;
	char fragment[1024];
	char vertex[1024];
	memset(fragment, 0, sizeof(fragment));
	memset(vertex, 0, sizeof(vertex));
	re_read_text("./resources/screen_shader_frag.glsl", fragment);
	re_read_text("./resources/screen_shader_vert.glsl", vertex);
	re_shader_program_t screen_shader;
	screen_shader = (re_shader_program_t){
		.name = "Screen shader",
		.source = {
			{.name = "Vertex",.source = vertex,.type = RE_VERTEX_SHADER},
			{.name = "Fragment",.source = fragment,.type = RE_FRAGMENT_SHADER}
		}
	};
	re_compile_shader(&screen_shader.source[0]);
	re_compile_shader(&screen_shader.source[1]);
	re_init_program(&screen_shader);

	memset(fragment, 0, sizeof(fragment));
	memset(vertex, 0, sizeof(vertex));
	re_read_text("./resources/scene_shader_frag.glsl", fragment);
	re_read_text("./resources/scene_shader_vert.glsl", vertex);
	re_shader_program_t scene_shader;
	scene_shader = (re_shader_program_t){
			.name = "Default",
			.source = {
				{.name = "Vertex Shader",.source = vertex,.type = RE_VERTEX_SHADER},
				{.name = "Fragment Shader",.source = fragment, .type = RE_FRAGMENT_SHADER}
			},

	};
	re_compile_shader(&scene_shader.source[0]);
	re_compile_shader(&scene_shader.source[1]);
	re_init_program(&scene_shader);
	pipeline->_main_renderpath._scene_fb = re_create_framebuffer(&(re_framebuffer_desc_t) {
		.attachment = RE_COLOR_ATTACHMENT,
			.filter = LINEAR,
			.format = SRGB
	});
	pipeline->_main_renderpath._screen_fb = (re_framebuffer_t*)malloc(sizeof(re_framebuffer_t));
	memset(pipeline->_main_renderpath._screen_fb, 0, sizeof(re_framebuffer_t));

	re_renderpass_desc_t scene_shader_desc = (re_renderpass_desc_t){ 
		.shader_program = &scene_shader,
		.type = COLOR_PASS,
		.target_framebuffer = pipeline->_main_renderpath._scene_fb,
		._renderpass_cb = &_on_default_scene_render ,
		.target = SCENE
	};
	re_renderpass_desc_t screen_shader_desc = (re_renderpass_desc_t){
		.shader_program = &screen_shader,.type = COLOR_PASS,
		.target_framebuffer = pipeline->_main_renderpath._screen_fb,
		._renderpass_cb = &_on_default_screen_render ,
		.target = SCREEN
	};
	re_renderpass_t* scene_pass = re_create_renderpass(&scene_shader_desc);
	re_renderpass_t* screen_pass = re_create_renderpass(&screen_shader_desc);
	linked_list_append(re_renderpass_t, &pipeline->_main_renderpath._linked_list, *scene_pass);
	linked_list_append(re_renderpass_t, &pipeline->_main_renderpath._linked_list, *screen_pass);
}

REALM_ENGINE_FUNC re_result_t re_init_gfx_pipeline()
{
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
	_screen_mesh.positions = (vec3*)malloc(sizeof(_screen_mesh_positions));
	_screen_mesh.texcoords = (vec2*)malloc(sizeof(_screen_uv));
	_screen_mesh.mesh_size = 4;
	_screen_mesh.triangles = (uint32_t*)malloc(sizeof(_screen_triangles));

	memcpy(_screen_mesh.positions, _screen_mesh_positions, sizeof(_screen_mesh_positions));
	memcpy(_screen_mesh.texcoords, _screen_uv, sizeof(_screen_uv));
	memcpy(_screen_mesh.triangles, _screen_triangles, sizeof(_screen_triangles));
	return RE_OK;

}

REALM_ENGINE_FUNC re_result_t re_pipeline_start_draw()
{

	re_gfx_pipeline_t* pipeline = RE_GRAPHICS_PIPELINE;
	//glUseProgram(pipeline->program._program_id);
	glBindVertexArray(pipeline->_vao);
	glBindBuffer(GL_ARRAY_BUFFER, pipeline->_vbo);

	//glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, pipeline->_ibo);

	uint32_t size = sizeof(mat4x4) * 3;
	re_bind_shader_block(pipeline->_re_global_data_block, RE_GLOBAL_DATA_REF, 0);
	re_update_shader_block(pipeline->_re_global_data_block, &pipeline->re_global_data->view_projection, 0, size);
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
	glClear(GL_COLOR_BUFFER_BIT);



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
		glUseProgram(pass.shader_program._program_id);
		pass._rendpass_cb(&pass, NULL);
		switch (pass.target)
		{
		case SCENE:
			linked_list_traverse(re_actor_t, actor, *root->children)
			{
				re_upload_mesh_data(&actor.mesh, &actor.transform);
				re_draw_triangles(6);
			}
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
#endif // !GFX_IMPL