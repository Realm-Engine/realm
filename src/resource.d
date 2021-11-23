module realm.resource;


immutable string vertexShader = "
#version 430 core\n
layout(location = 0) in vec3 v_Position;\n
\n
void main()\n
{\n
\n
	gl_Position = vec4(v_Position,1.0);\n
}\n

	";

immutable string fragmentShader = "
#version 430 core\n
layout(std140, binding = 0) uniform _reGlobalData\n
{\n
mat4 _viewProjection;\n
};\n
\n
out vec4 outColor;\n
\n
void main()\n
{\n
outColor = vec4(1.0,0.0,0.0,1.0);\n
}\n
";
