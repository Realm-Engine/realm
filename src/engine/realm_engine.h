#pragma once


#include "GLFW/glfw3.h"
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include "re_math.h"
#define RE_GLOBAL_DATA_REF "_reGlobalData"
#define REALM_ENGINE_FUNC static inline



typedef struct re_global_data_t
{
	mat4x4_t view_proj_mat;
} re_global_data_t;

#include "gfx_ogl.h"





typedef struct re_mesh_t
{
	vec3_t* positions;
	vec3_t* normals;
	vec3_t* texcoords;
	uint32_t* triangles;
	uint16_t mesh_size;
}re_mesh_t;

typedef struct re_app_desc_t
{
	int width;
	int height; 
	char title[64];
}re_app_desc_t;


struct re_context_t;
typedef struct re_event_handler_desc_t
{
	void(*on_update)(struct re_context_t* ctx);
	void(*on_start)(struct re_context_t* ctx);

}re_event_handler_desc_t;


typedef struct re_context_t
{
	GLFWwindow* _window;
	re_app_desc_t app;
	re_event_handler_desc_t event_handlers;

}re_context_t;








REALM_ENGINE_FUNC re_context_t* re_init(re_app_desc_t app) {
	if (!glfwInit())
	{
		printf("Could not init glfw!\n");
	}
	re_context_t* ctx = (re_context_t*)malloc(sizeof(re_context_t));
	
	ctx->_window = glfwCreateWindow(app.width, app.height, app.title, NULL, NULL);
	memcpy(&ctx->app, &app, sizeof(re_context_t));
	glfwMakeContextCurrent(ctx->_window);

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

