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


vec3 calculateDiffuse(vec3 normal)
{

	float amount = max(dot(normal,vec3(-mainLight.direction)),0.0);
	
	return (amount * mainLight.color.rgb);

}

vec3 calculateSpecular(vec3 normal, vec3 fragPosition, float specularPower,float shinyness)
{
	vec3 viewDirection = normalize(camera.position.xyz - fragPosition);
	vec3 reflectDirection = reflect(-mainLight.direction.xyz, normalize(normal));
	float specularFactor = pow(max(dot(viewDirection,reflectDirection),0.0),shinyness);
	vec3 specular = specularPower * specularFactor * mainLight.color.rgb;
	return vec3(specularFactor);

}


vec2 samplerUV(vec4 to,vec2 texCoord)
{
	return (vec2( texCoord.x,1-texCoord.y) *  vec2(to.x,to.y)) + vec2(to.z,to.w);
}


float linearDepth(float depth)
{
	
	float near = camera.nearPlane;
	float far = camera.farPlane;
	return (2.0 * near * far)/(far + near - depth * (far - near));

	

}


layout(location = 3) uniform sampler2D atlasTextures[16];


#define SAMPLE_TEXTURE(t,texCoord) texture(objectTexture, samplerUV(getObjectData( t ), texCoord ))
