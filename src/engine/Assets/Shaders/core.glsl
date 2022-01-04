struct DirectionalLight
{
        vec4 direction;
        vec4 color;
};
layout(std140, binding = 0) uniform _reGloblaData
{
	mat4 u_vp;
    DirectionalLight mainLight;
    mat4 lightSpaceMatrix;

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


uniform sampler2D atlasTextures[16];

