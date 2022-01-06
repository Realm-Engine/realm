#shader shared
#define OBJECT_DATA
struct ObjectData
{
	vec4 color;
	vec4 heightMap;
	float oceanLevel;
	float packing;
	float heightStrength;
	float packing2;
	vec4 shallowColor;
	vec4 deepColor;

	
};
#shader vertex waterVertex
vec4 vertex(REVertexData IN)
{
	float oceanLevel = IN.objectData.oceanLevel;
	vec3 position = IN.position + vec3(0,oceanLevel,0);

	RESurfaceDataOut.TBN = calculateTBN();
	RESurfaceDataOut.objectData = IN.objectData;
	RESurfaceDataOut.objectId = IN.objectId;
	RESurfaceDataOut.posCS = u_vp * vec4(position, 1.0);
	RESurfaceDataOut.posWS = v_Position;
	RESurfaceDataOut.texCoord = IN.texCoord;
	RESurfaceDataOut.normal = IN.normal;
    RESurfaceDataOut.lightSpacePosition = lightSpaceMatrix * vec4(position,1.0);
	return RESurfaceDataOut.posCS;

}

#shader fragment waterFragment

vec3 grayToNormal(sampler2D grayTexture, vec2 uv, float delta)
{
	vec2 dx = uv + vec2(delta, 0);
	vec2 dy = uv + vec2(0, delta);
	vec4 graySample = texture(grayTexture, uv);
	vec4 sampleX = texture(grayTexture, dx);
	vec4 sampleY = texture(grayTexture, dy);
	float ab = graySample.x - sampleX.x;
	float ac = graySample.x - sampleY.x;
	return cross(vec3(1, 0, ab), vec3(0, 1, ac));

}



vec4 fragment()
{
	float height = texture(objectTexture, samplerUV(getObjectData(heightMap), RESurfaceDataIn.texCoord)).x;
	height = height * getObjectData(heightStrength);
	vec3 normal =  RESurfaceDataIn.normal;

	vec3 ambient = vec3(0.1);
	vec3 deepColor = vec3(7,52,207).rgb;
	vec3 shallowColor = vec3(6,184,207).rgb;
	
	vec3 color = smoothstep(normalize(deepColor), normalize(shallowColor), vec3(height));
	vec3 lighting = calculateDiffuse(normal) * color;
	return vec4(color,height );
}