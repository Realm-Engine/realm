

layout (std430,binding = 1) buffer _perObjectData
{
	Material data[];
};


in RESurfaceData
{
	vec3 posWS;
	vec4 posCS;
	vec2 texCoord;
	flat int objectId;
	Material material;
	vec3 normal;
	mat3 TBN;
	vec4 lightSpacePosition;

} RESurfaceDataIn;
#define objectTexture atlasTextures[RESurfaceDataIn.objectId]
#define getObjectData(v) RESurfaceDataIn.material.v
layout (location = 0) out vec4 FragColor;
vec4 fragment();
layout(location = 0) uniform sampler2D cameraDepthTexture;
layout(location = 1) uniform sampler2D cameraScreenTexture;
layout(location = 2) uniform sampler2D shadowMap;




float shadowMapSample(vec4 lightSpace)
{
	vec3 projCoords = lightSpace.xyz/lightSpace.w;
	projCoords = projCoords * 0.5 + 0.5;
	float closest= texture(shadowMap,projCoords.xy).r;
	return closest;
}


vec3 transformNormal(vec3 normal)
{
	normal = normal * 2 - 1;
	return normalize(RESurfaceDataIn.TBN * normal);

}

float calculateShadow(vec4 lightSpace,float bias)
{
	vec3 projCoords = lightSpace.xyz/lightSpace.w;
	projCoords = projCoords * 0.5 + 0.5;
	float closest= texture(shadowMap,projCoords.xy).r;
	float currentDepth = projCoords.z;
	float shadow = 0.0;
	vec2 texelSize = 1.0/textureSize(shadowMap,0);
	for(int x = -1; x <= 1; ++x)
	{
		for(int y = -1; y <= 1; ++y)
		{
			float fragmentDepth = texture(shadowMap,projCoords.xy + vec2(x,y) * texelSize).r;
			shadow += currentDepth - bias > fragmentDepth ? 1.0 : 0.0;
		}
	}
	
	return shadow / 9;
}

void main()
{ 
	FragColor = fragment();
}