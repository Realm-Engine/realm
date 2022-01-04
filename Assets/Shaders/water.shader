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
	vec4 noise1;
	vec4 noise2;
	float time;
	float packing3;
	float scrollSpeed;
	float packing4;
	vec4 distortion;
	
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

vec3 calculateDistortion(vec2 scroll)
{
	vec2 uv = samplerUV(getObjectData(distortion), RESurfaceDataIn.texCoord) + scroll;
	uv.x = mod(uv.x, getObjectData(distortion).z);
	vec3 distortionNormal = grayToNormal(objectTexture, uv, 0.0071358);
	vec3 screenPosition = RESurfaceDataIn.posCS.xyz/ RESurfaceDataIn.posCS.w;
	screenPosition = screenPosition * 0.5 + 0.5;
	vec3 distortion = screenPosition * distortionNormal.xyz;
	return distortion;


}

vec3 calculateNormal()
{
	float t = getObjectData(time) / getObjectData(scrollSpeed);
	vec2 scroll = t * vec2(1,0);
	vec3 distortion = calculateDistortion(scroll);
	vec2 noise1uv = samplerUV(getObjectData(noise1), RESurfaceDataIn.texCoord) + distortion.xy;
	vec2 noise2uv = samplerUV(getObjectData(noise2), RESurfaceDataIn.texCoord)  + distortion.xy;
	noise1uv.x = mod(noise1uv.x, getObjectData(noise1).z);
	noise2uv.x = mod(noise2uv.x, getObjectData(noise2).z);

	vec3 normalSample1 = grayToNormal(objectTexture, noise1uv, 0.0071358);
	vec3 normalSample2 = grayToNormal(objectTexture, noise2uv, 0.0071358);

	vec3 normal = normalSample1 + normalSample2;
	return normal;

}



vec4 fragment()
{
	float height = texture(objectTexture, samplerUV(getObjectData(heightMap), RESurfaceDataIn.texCoord)).x;
	height = height * getObjectData(heightStrength);
	vec3 normal = RESurfaceDataIn.TBN * calculateNormal();

	vec3 ambient = vec3(0.1);
	vec3 deepColor = vec3(7,52,207).rgb;
	vec3 shallowColor = vec3(6,184,207).rgb;
	
	vec3 color = smoothstep(normalize(deepColor), normalize(shallowColor), vec3(height));
	vec3 lighting = calculateDiffuse(normal, vec3(0.25) * color);
	return vec4(lighting,1.0 );
}