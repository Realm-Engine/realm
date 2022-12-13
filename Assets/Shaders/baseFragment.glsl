

layout(std140, binding = 1) uniform _perObjectData
{
	Material data[16];
};
layout(std140, binding = 2) uniform _objectToWorld
{
	mat4 objectToWorld[16];
};

in RESurfaceData
{
	vec3 posWS;
	vec4 posCS;
	vec2 texCoord;
	flat int objectId;
	//Material material;
	vec3 normal;
	mat3 TBN;
	/*vec4 lightSpacePosition;
	vec4 eyeSpacePosition;*/

} RESurfaceDataIn;
#define objectTexture atlasTextures[RESurfaceDataIn.objectId]
#define getObjectData(v) data[RESurfaceDataIn.objectId].v
layout (location = 0) out vec4 FragColor;
vec4 fragment();
layout(location = 0) uniform sampler2D cameraDepthTexture;
layout(location = 1) uniform sampler2DMS cameraScreenTexture;
layout(location = 2) uniform sampler2D shadowMap;
layout(location = 3) uniform samplerCube envSkybox;





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