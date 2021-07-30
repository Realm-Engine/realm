#include <stdint.h>
static char vs[] = "#version 430 core\n\
layout(location = 0) in vec3 _position;\n\
out vec3 Color;\n\
uniform mat4 u_vp;\n\
void main() {\n\
\
	gl_Position = vec4(_position.xyz, 1);\n\
	Color = vec3(1,1,1);\n\
}";

static char fs[] = "#version 430 core\n\
out vec4 FragColor;\n\
in vec3 Color;\n\
void main()\n\
{\n\
	FragColor = vec4(Color, 1.0);\n\
}";
static uint32_t square_triangles[6] = { 0,1,2,2,3,0 };
static float square_model[4][3] = {
	{0,0,-1.0f},
	{0,5,-1.0f},
	{5,5,-1.0f},
	{5,0,-1.0f}
};


