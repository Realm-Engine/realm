#pragma once
#include "realm_engine.h"
#include <glad/glad.h>
#include <stdint.h>
#include "math.h"
#include <stdlib.h>
#include<stdio.h>
#include <conio.h>

typedef enum re_shader_type_t
{
	RE_VERTEX_SHADER,
	RE_FRAGMENT_SHADER


} re_shader_type_t;

typedef enum re_result_t
{
	RE_OK,
	RE_ERROR
} re_result_t;







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




typedef struct re_gfx_pipeline_t
{
	re_shader_program_t program;
	uint16_t num_attribs;
	re_vertex_attr_desc_t attributes[GL_MAX_VERTEX_ATTRIBS];
	GLuint _vao;
	GLuint _vbo;
	GLuint _ibo;
	re_shader_block_t* _re_global_data_block;
	re_shader_block_t* _re_user_data_block;
	re_global_data_t* re_global_data;

}re_gfx_pipeline_t;





REALM_ENGINE_FUNC GLenum _re_shader_type_to_glenum(re_shader_type_t type)
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
		RE_VERTEX_SHADER;
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
	default:
		break;
	}
	return user_type;
}

REALM_ENGINE_FUNC re_result_t re_compile_shader(re_shader_t* sh)
{
	sh->_shader_id = glCreateShader(_re_shader_type_to_glenum(sh->type));
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

	program_data->_program_id = glCreateProgram();
	for (int i = 0; i < 2; i++)
	{
		glAttachShader(program_data->_program_id, program_data->source[i]._shader_id);
	}
	glLinkProgram(program_data->_program_id);
	for (int i = 0; i < 2; i++)
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


REALM_ENGINE_FUNC re_result_t re_init_gfx()
{
	gladLoadGLLoader((GLADloadproc)glfwGetProcAddress);
	glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 4);
	glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3);
	glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);
	return RE_OK;



}



REALM_ENGINE_FUNC re_result_t re_upload_vertex_data(vec3* positions, uint16_t num_vertices)
{
	uint32_t size = num_vertices * sizeof(vec3);
	glBufferData(GL_ARRAY_BUFFER, size, positions, GL_DYNAMIC_DRAW);
	return RE_OK;


}

REALM_ENGINE_FUNC re_result_t re_upload_index_data(uint32_t* triangles, uint32_t num_triangles)
{
	
	glBufferData(GL_ELEMENT_ARRAY_BUFFER, num_triangles * sizeof(uint32_t), triangles, GL_DYNAMIC_DRAW);
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

	uint32_t stride;

	for (int i = 0; i < pipeline->num_attribs; i++)
	{
		re_vertex_attr_desc_t attribute = pipeline->attributes[i];
		GLenum type = _re_type_to_gltype(attribute.type);
		glEnableVertexAttribArray(attribute.index);
		glVertexAttribPointer(attribute.index, SHADER_VAR_ELEMENTS(attribute.type), type, GL_FALSE, 0 * sizeof(float), (void*)attribute.offset);
		
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





REALM_ENGINE_FUNC re_result_t re_query_userdata_layout(re_gfx_pipeline_t* pipeline, const char* name, re_user_data_layout_t* layout)
{
	re_shader_block_t* block = pipeline->_re_user_data_block;
	re_shader_program_t program = pipeline->program;
	GLuint block_index = block->ref_index;
	int32_t num_uniforms = 0;
	glGetActiveUniformBlockiv(program._program_id, block_index, GL_UNIFORM_BLOCK_ACTIVE_UNIFORMS, &num_uniforms);
	GLint* block_uniform_indices = (int32_t*)(malloc(sizeof(GLint)*num_uniforms));
	glGetActiveUniformBlockiv(program._program_id, block_index, GL_UNIFORM_BLOCK_ACTIVE_UNIFORM_INDICES, block_uniform_indices);
	int32_t* name_length = (int32_t*)malloc(sizeof(int32_t) * num_uniforms);
	layout->var_offsets = (int32_t*)malloc(sizeof(uint32_t) * num_uniforms);
	layout->num_vars = num_uniforms;
	layout->var_types = (re_user_data_var_types*)malloc(sizeof(re_user_data_var_types) * num_uniforms);
	layout->var_names = (char**)malloc(num_uniforms * 64);
	layout->block_size = 0;
	int32_t* types = (int32_t*)malloc(sizeof(int32_t) * num_uniforms);
	glGetActiveUniformsiv(program._program_id, num_uniforms, (GLuint*)block_uniform_indices, GL_UNIFORM_NAME_LENGTH, name_length);
	glGetActiveUniformsiv(program._program_id, num_uniforms, (GLuint*)block_uniform_indices, GL_UNIFORM_OFFSET, layout->var_offsets);
	glGetActiveUniformsiv(program._program_id, num_uniforms, (GLuint*)block_uniform_indices, GL_UNIFORM_TYPE, types);

	for (int i = 0; i < num_uniforms; i++)
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
	free(name_length);
	free(types);
	free(block_uniform_indices);
	
	return RE_OK;

}

REALM_ENGINE_FUNC int32_t re_get_uniform_index(re_user_data_layout_t* layout, const char* name)
{
	for (int i = 0; i < layout->num_vars; i++)
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
		glBufferSubData(GL_UNIFORM_BUFFER, 0, sizeof(vec4), &value);
	}


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
