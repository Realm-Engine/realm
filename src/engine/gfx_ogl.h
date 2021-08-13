#ifndef GFX_IMPL
#define GFX_IMPL


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
	re_texture_t* _framebuffer_texture;
	re_framebuffer_attachment attachment;

}re_framebuffer_t;

typedef struct re_gfx_pipeline_t
{
	re_shader_program_t program;
	uint16_t num_attribs;

	re_vertex_attr_desc_t attributes[GL_MAX_VERTEX_ATTRIBS];
	uint16_t vertex_layout_size;
	GLuint _vao;
	GLuint _vbo;
	GLuint _ibo;
	re_shader_block_t* _re_global_data_block;
	re_shader_block_t* _re_user_data_block;
	re_global_data_t* re_global_data;


}re_gfx_pipeline_t;
#define _ENUM_CONVERSION_FUNCTION(T, v) REALM_ENGINE_FUNC GLenum _##T##_to_glenum(T v)

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


REALM_ENGINE_FUNC re_framebuffer_t* re_create_framebuffer()
{
	re_framebuffer_t* buffer = (re_framebuffer_t*)malloc(sizeof(re_framebuffer_t));
	glGenFramebuffers(1, &buffer->_id);
	glBindFramebuffer(GL_FRAMEBUFFER, buffer->_id);



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
REALM_ENGINE_FUNC re_result_t re_upload_mesh_data(re_mesh_t* mesh,re_transform_t* transform,re_gfx_pipeline_t* pipeline)
{

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
	

	
	re_upload_index_data(mesh->triangles,6);
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

REALM_ENGINE_FUNC re_result_t re_bind_pipeline_attributes(re_gfx_pipeline_t* pipeline)
{
	pipeline->vertex_layout_size = 0;
	uint32_t stride = 0;
	int i;
	for ( i = 0; i < pipeline->num_attribs; i++)
	{
		re_vertex_attr_desc_t attribute = pipeline->attributes[i];
		GLenum type = _re_type_to_gltype(attribute.type);
		glEnableVertexAttribArray(attribute.index);
		glVertexAttribPointer(attribute.index, SHADER_VAR_ELEMENTS(attribute.type), type, GL_FALSE,5 * sizeof(float), (void*)attribute.offset);
		pipeline->vertex_layout_size += SHADER_VAR_SIZE(attribute.type);
	}
	return RE_OK;
}

REALM_ENGINE_FUNC re_result_t re_pipeline_end_draw(re_gfx_pipeline_t* pipeline)
{
	glBufferData(GL_ARRAY_BUFFER, 0, NULL, GL_STATIC_DRAW);
	glBufferData(GL_ELEMENT_ARRAY_BUFFER, 0, NULL, GL_STATIC_DRAW);
	glBindVertexArray(0);
	glUseProgram(0);
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
	glBindBuffer(GL_ARRAY_BUFFER, 0);
	glBindBuffer(GL_UNIFORM_BUFFER, 0);
	return RE_OK;
}





REALM_ENGINE_FUNC re_result_t re_query_userdata_layout(re_gfx_pipeline_t* pipeline,  re_user_data_layout_t* layout)
{
	re_shader_block_t* block = pipeline->_re_user_data_block;
	re_shader_program_t program = pipeline->program;
	GLuint block_index = block->ref_index;
	int32_t num_uniforms = 0;
	glGetActiveUniformBlockiv(program._program_id, block_index, GL_UNIFORM_BLOCK_ACTIVE_UNIFORMS, &num_uniforms);
	GLint* block_uniform_indices = (int32_t*)(malloc(sizeof(GLint)*num_uniforms));
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
	for ( i = 0; i < num_uniforms; i++)
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

REALM_ENGINE_FUNC re_result_t re_set_texture(re_gfx_pipeline_t* pipeline, const char* name, re_texture_t* texture)
{
	uint32_t location = glGetUniformLocation(pipeline->program._program_id, name);
	glBindTextureUnit(location, texture->_handle);
}



REALM_ENGINE_FUNC re_shader_block_t* re_create_shader_block(re_shader_program_t* program,const char* block_name,void* initial_data,  uint32_t initial_size)
{
	re_shader_block_t* block = (re_shader_block_t*)malloc(sizeof(re_shader_block_t));
	
	

	glGenBuffers(1, &block->_id);
	glBindBuffer(GL_UNIFORM_BUFFER, block->_id);
	glBufferData(GL_UNIFORM_BUFFER, initial_size, initial_data, GL_DYNAMIC_DRAW);
	GLuint index = glGetUniformBlockIndex(program->_program_id, block_name);
	block->ref_index = index;
	return block;

}

REALM_ENGINE_FUNC re_result_t re_bind_shader_block(re_shader_block_t* block, const char* reference,uint32_t binding_point, re_shader_program_t program)
{
	glBindBuffer(GL_UNIFORM_BUFFER, block->_id);
	
	glBindBufferBase(GL_UNIFORM_BUFFER, binding_point, block->_id);
	
	return RE_OK;
}



REALM_ENGINE_FUNC re_result_t re_update_shader_block(re_shader_block_t* block,void* data,uint32_t offset, uint32_t size)
{
	
	glBufferData(GL_UNIFORM_BUFFER, size, data, GL_DYNAMIC_DRAW);
	block->size = size;
	return RE_OK;
}

REALM_ENGINE_FUNC re_result_t re_set_userdata_block(re_gfx_pipeline_t* pipeline, void* data, uint32_t size)
{
	re_update_shader_block(pipeline->_re_user_data_block, data, 0, size);
	return RE_OK;
}

REALM_ENGINE_FUNC re_result_t re_pipeline_start_draw(re_gfx_pipeline_t* pipeline)
{


	glUseProgram(pipeline->program._program_id);
	glBindVertexArray(pipeline->_vao);
	glBindBuffer(GL_ARRAY_BUFFER, pipeline->_vbo);
	
	//glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, pipeline->_ibo);
	
	uint32_t size = sizeof(mat4x4) * 3;
	re_bind_shader_block(pipeline->_re_global_data_block, RE_GLOBAL_DATA_REF, 0, pipeline->program);
	re_update_shader_block(pipeline->_re_global_data_block, &pipeline->re_global_data->view_projection, 0, size);
	re_bind_shader_block(pipeline->_re_user_data_block, RE_USER_DATA_REF, 1, pipeline->program);
	re_update_shader_block(pipeline->_re_user_data_block, RE_USER_DATA_REF, 0, pipeline->_re_user_data_block->size);
	//re_update_shader_block(pipeline->_re_global_data_block, &new_vec4(1.0, 1.0, 1.0, 1.0), 0, sizeof(vec4));
	return RE_OK;

}

REALM_ENGINE_FUNC re_result_t re_gen_texture(re_texture_t* texture)
{
	GLenum wrap = _re_texture_wrap_func_to_glenum(texture->wrap);
	GLenum filter = _re_texture_wrap_func_to_glenum(texture->filter);
	GLenum target = _re_image_type_to_glenum(texture->format);
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



REALM_ENGINE_FUNC re_result_t re_update_vp(re_gfx_pipeline_t* pipeline, mat4x4 matrices[3])
{


	memcpy(&pipeline->re_global_data, &matrices, sizeof(mat4x4) * 3);


	return RE_OK;
}




REALM_ENGINE_FUNC re_result_t re_init_gfx_pipeline(re_gfx_pipeline_t* pipeline)
{
	glGenVertexArrays(1, &pipeline->_vao);

	glBindVertexArray(pipeline->_vao);

	glGenBuffers(1, &pipeline->_vbo);
	glGenBuffers(1, &pipeline->_ibo);

	glBindBuffer(GL_ARRAY_BUFFER, pipeline->_vbo);
	re_bind_pipeline_attributes(pipeline);


	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, pipeline->_ibo);


	glBindVertexArray(0);
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
	glBindBuffer(GL_ARRAY_BUFFER, 0);
	
	pipeline->_re_global_data_block = re_create_shader_block(&pipeline->program,RE_GLOBAL_DATA_REF, 0,0);
	pipeline->re_global_data = (re_global_data_t*)malloc(sizeof(re_global_data_t));
	memset(pipeline->re_global_data, 0, sizeof(re_global_data_t));
	glBindBuffer(GL_UNIFORM_BUFFER, 0);
	pipeline->_re_user_data_block = re_create_shader_block(&pipeline->program,RE_USER_DATA_REF,0,0);
	glBindBuffer(GL_UNIFORM_BUFFER, 0);

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


#endif // !GFX_IMPL