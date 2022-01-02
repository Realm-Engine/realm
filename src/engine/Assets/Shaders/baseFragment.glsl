

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

} RESurfaceDataIn;
#define objectTexture atlasTextures[RESurfaceDataIn.objectId]
out vec4 FragColor;
vec4 fragment();
void main()
{ 
	FragColor = fragment();
}