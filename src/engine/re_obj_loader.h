#ifndef RE_OBJ_H
#define RE_OBJ_H
#include "realm_engine.h"
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
REALM_ENGINE_FUNC void re_parse_obj_geo(const char* path, re_mesh_t* mesh);
#define RE_OBJ_IMPL
#ifdef RE_OBJ_IMPL


REALM_ENGINE_FUNC vec2 _re_parse_vector2(char* line)
{

	float nums[2] = { 0,0 };
	char* current = line;
	size_t current_idx = 0;
	char* token = strtok(line, " ");
	float r;
	while (token != NULL)
	{
		r = strtof(&token[0], NULL);


		if (r != 0.0f)
		{
			nums[current_idx] = r;
			current_idx++;
		}
		else if (strcmp(token, "0") == 0)
		{
			nums[current_idx] = r;
			current_idx++;
		}

		errno = ENOENT;
		token = strtok(NULL, " ");

	}

	return new_vec2(nums[0], nums[1]);

}

REALM_ENGINE_FUNC vec3 _re_parse_vector3(char* line)
{



	float nums[3] = { 0,0,0 };
	char* current = line;
	size_t current_idx = 0;
	char* token = strtok(line," ");
	float r;
	while(token != NULL)
	{
		r = strtof(token, NULL);

		
		if (r != 0.0f)
		{
			nums[current_idx] = r;
			current_idx++;
		}
		else if (strcmp(token,"0") == 0)
		{
			nums[current_idx] = r;
			current_idx++;
		}

		errno = ENOENT;
		token = strtok(NULL, " ");

	}

	return new_vec3(nums[0], nums[1], nums[2]);

}

REALM_ENGINE_FUNC void re_parse_obj_tris(const char* path, re_mesh_t* mesh)
{

}

REALM_ENGINE_FUNC void re_parse_obj_geo(const char* path,re_mesh_t* mesh)
{
	vector(vec3) v = new_vector(vec3,5);
	vector(vec2) vt = new_vector(vec2, 5);
	vector(vec3) vn = new_vector(vec3, 5);
	vector(uint32_t) indices = new_vector(uint32_t, 5);
	mesh->positions = new_vector(vec3, 5);
	mesh->normals = new_vector(vec3, 5);
	mesh->texcoords = new_vector(vec2, 5);
	/*long fsize = re_get_file_size(path);
	char* buffer = (char*)malloc(sizeof(fsize + 1));*/

	FILE* fp;
	fp = fopen(path, "r");
	char line[100];
	while (fgets(line, 100, fp) != NULL)
	{
		char* ch = line;
		while (*ch != '\n')
		{
			if (*ch == 'v')
			{
				switch (*(ch + 1))
				{
				case 't':
					vec2 uv = _re_parse_vector2(line);
					printf("\nX:%f, Y:%d",uv.x,uv.y);
					vector_insert(vec2, &vt, uv);
					break;
				case 'n':
					vec3 normal = _re_parse_vector3(line);
					vector_insert(vec3, &vn, normal);
					break;
				case ' ':
					vec3 vertex = _re_parse_vector3(line);
					vector_insert(vec3, &v, vertex);

					break;
				default:
					re_log(RE_LOW, "Unknown");
					break;
				}

				break;
			}

			else if (*ch == 'f')
			{
				char line_copy[64];
				strcpy(line_copy, line);
				char* space = strtok(line_copy, " ");
				char space_copy[64];
				while (space != NULL)
				{
					strcpy(space_copy, space);
					char* index = strtok(space_copy, "/");
					size_t index_slot = 0;
					while (index != NULL)
					{
						int r = atoi(index);
						if (r != 0)
						{

							switch (index_slot)
							{
							case 0:
								vector_insert(vec3, &mesh->positions, v.elements[r]);
								vector_insert(uint32_t, &indices, (uint32_t)r);
								break;
							case 1:
								vector_insert(vec2, &mesh->texcoords, vt.elements[r]);
								break;
							case 2:
								vector_insert(vec3, &mesh->normals, vn.elements[r]);
								break;
							default:
								break;
							}
							index_slot++;
						}
						index = strtok(NULL, "/");
					}
					space = strtok(NULL, " ");

				}
			}
			ch++;
		}

	}
	re_fill_mesh(mesh, v.elements, vn.elements, vt.elements, v.count);
}

#endif

#endif