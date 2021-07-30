#pragma once
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

typedef enum re_result_t
{
	RE_OK,
	RE_ERROR
} re_result_t;

typedef enum re_vertex_type_t
{
	FLOAT = 0x411,
	FLOAT2 = 0x421,
	FLOAT3 = 0x431,
	FLOAT4 = 0x441

}re_vertex_type_t;

#define SHADER_VAR_BYTES(var)  (int)var >> 8
#define SHADER_VAR_ELEMENTS(var)  ((int) var & 0x0F0) >> 4
#define SHADER_VAR_TYPE(var) (int) var & 0x00F



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



REALM_ENGINE_FUNC re_result_t re_upload_vertex_data(vec3_t* positions, uint16_t num_vertices)
{
	uint32_t size = num_vertices * sizeof(vec3_t);
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

REALM_ENGINE_FUNC re_shader_block_t* re_create_shader_block(void* initial_data,  uint32_t initial_size)
{
	re_shader_block_t* block = (re_shader_block_t*)malloc(sizeof(re_shader_block_t));
	
	

	glGenBuffers(1, &block->_id);
	glBindBuffer(GL_UNIFORM_BUFFER, block->_id);
	glBufferData(GL_UNIFORM_BUFFER, initial_size, initial_data, GL_DYNAMIC_DRAW);
	
	return block;

}

REALM_ENGINE_FUNC re_result_t re_bind_shader_block(re_shader_block_t* block, const char* reference,uint32_t binding_point, re_shader_program_t program)
{
	glBindBuffer(GL_UNIFORM_BUFFER, block->_id);
	GLuint index = glGetUniformBlockIndex(program._program_id, reference);
	glBindBufferBase(GL_UNIFORM_BUFFER, binding_point, block->_id);
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
	
	uint32_t size = sizeof(mat4x4_t);
	re_bind_shader_block(pipeline->_re_global_data_block, RE_GLOBAL_DATA_REF, 0, pipeline->program);
	re_update_shader_block(pipeline->_re_global_data_block, &pipeline->re_global_data->view_proj_mat, 0, size);
	return RE_OK;

}

REALM_ENGINE_FUNC re_result_t re_update_vp(re_gfx_pipeline_t* pipeline, mat4x4_t vp)
{


	memcpy(&pipeline->re_global_data->view_proj_mat, &vp, sizeof(mat4x4_t));


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
	
	pipeline->_re_global_data_block = re_create_shader_block( 0,0);
	pipeline->re_global_data = (re_global_data_t*)malloc(sizeof(re_global_data_t));
	memset(pipeline->re_global_data, 0, sizeof(re_global_data_t));
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
