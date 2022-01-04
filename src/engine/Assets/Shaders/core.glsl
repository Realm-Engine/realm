struct DirectionalLight
{
        vec4 direction;
        vec4 color;
};

struct Camera
{
	vec4 position;
	vec4 direction;
	float nearPlane;
	float farPlane;
	vec2 size;

};

layout(std140, binding = 0) uniform _reGloblaData
{
	mat4 u_vp;
    DirectionalLight mainLight;
    mat4 lightSpaceMatrix;
	Camera camera;

};


vec3 calculateDiffuse(vec3 normal,vec3 ambient)
{
	vec3 norm = normalize(normal);
	float amount = max(dot(norm,vec3(-mainLight.direction)),0.0);
	return ambient + (amount * vec3(mainLight.color) * 5);

}


vec2 samplerUV(vec4 to,vec2 texCoord)
{
	return (texCoord * vec2(to.x,to.y)) + vec2(to.z,to.w);
}

float linearDepth(float depth)
{
	
	float near = camera.nearPlane;
	float far = camera.farPlane;
	return (2.0 * near * far)/(far + near - depth * (far - near));

	

}


uniform sampler2D atlasTextures[16];

