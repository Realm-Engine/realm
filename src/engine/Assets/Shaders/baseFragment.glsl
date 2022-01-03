

layout (std430,binding = 1) buffer _perObjectData
{
	ObjectData data[];
};


in RESurfaceData
{
	vec3 posWS;
	vec4 posCS;
	vec2 texCoord;
	flat int objectId;
	ObjectData objectData;
	vec3 normal;
	mat3 TBN;
	vec4 lightSpacePosition;

} RESurfaceDataIn;
#define objectTexture atlasTextures[RESurfaceDataIn.objectId]
out vec4 FragColor;
vec4 fragment();
layout(location = 2) uniform sampler2D shadowMap;

vec2 calcShadowMapCoordinates(vec4 lightSpace)
{
	vec3 projCoords = lightSpace.xyz/lightSpace.w;
	projCoords *0.5 + 0.5;
	
	return vec2(projCoords.xy);
}



float calculateShadow(vec4 lightSpace,float bias)
{
	vec3 projCoords = lightSpace.xyz/lightSpace.w;
	projCoords = projCoords * 0.5 + 0.5;
	float closest= texture(shadowMap,projCoords.xy).r;
	float currentDepth = projCoords.z;
	float shadow = currentDepth - bias > closest ? 1.0 : 0.0;
	return shadow;
}

void main()
{ 
	FragColor = fragment();
}