



#shader shared

struct Material
{
	vec4 normalHeightMap;
	vec4 climateMap;
	float heightStrength;
	float packing1;
	float oceanLevel;
	float height;
};





#shader vertex worldVertex
vec4 vertex(REVertexData IN)
{
	vec4 climateData = SAMPLE_TEXTURE(climateMap, IN.texCoord);
	float moisture = climateData.g;
	float isWater = step(1, moisture);
	float heightSample = SAMPLE_TEXTURE(normalHeightMap, IN.texCoord).a;
	float height = (heightSample.x) * getObjectData(heightStrength);
	height = mix(height, getObjectData(oceanLevel), isWater);
	IN.material.height = height;
	vec3 position = v_Position + vec3(0, 0, 0);
	RESurfaceDataOut.TBN = calculateTBN();
	RESurfaceDataOut.material = IN.material;
	RESurfaceDataOut.objectId = IN.objectId;
	RESurfaceDataOut.posCS = u_vp * vec4(position, 1.0);
	RESurfaceDataOut.posWS = position;
	RESurfaceDataOut.texCoord = IN.texCoord;
	RESurfaceDataOut.normal = IN.normal;
	RESurfaceDataOut.lightSpacePosition = lightSpaceMatrix * vec4(position, 1.0);

	return RESurfaceDataOut.posCS;



}

#shader fragment worldFragment


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

vec3 calculateWaterColor()
{
	float height = getObjectData(height);
	vec3 deepColor = vec3(7, 52, 207).rgb;
	vec3 shallowColor = vec3(6, 184, 207).rgb;
	vec3 color = mix(deepColor, shallowColor, clamp(vec3(height), vec3(0), vec3(1)));
	return color;
}

vec3 calculateBiome()
{

	float distanceFromWater =  getObjectData(height) / getObjectData(heightStrength);
	vec4 climateData = SAMPLE_TEXTURE(climateMap, RESurfaceDataIn.texCoord);
	float heat = climateData.r;
	float shoreDistance = climateData.b;
	float moisture = climateData.g;
	int isMoist = int(step(0.5, moisture));
	int isHot = int(step(0.9, heat));
	int isWater = int(step(1, moisture));
	int isIce = int(step(0.95, 1 - heat));
	int isDry = 1 - isMoist;
	int isCold = 1 -isHot;
	
	int isDesert = int(step(0.95, heat));


	vec3 biome = vec3(0);
	biome = mix(vec3(31, 85, 42), vec3(64, 69, 46), distanceFromWater);
	biome = mix(biome, vec3(178, 183, 2), isDesert);

	biome = mix(biome, calculateWaterColor(), isWater);
	biome = normalize(biome);
	biome = mix(biome, vec3(1.0), isIce);

	return vec3(biome);

}

vec4 fragment()
{
	float height = getObjectData(height) / getObjectData(heightStrength);
	float ocean = getObjectData(oceanLevel) / getObjectData(heightStrength);
	float dist = distance(ocean, height);
	vec3 terrainColor = calculateBiome();


	vec4 climateData = SAMPLE_TEXTURE(climateMap, RESurfaceDataIn.texCoord);

	//terrainColor *= border;
	float gamma = 2.2;
	terrainColor = pow(terrainColor, vec3(2.2));


	//outColor = vec4(height,1-height,0,1.0);
	vec3 normal = SAMPLE_TEXTURE(normalHeightMap, RESurfaceDataIn.texCoord).rgb;
	normal = normal * 2;
	normal = normalize(RESurfaceDataIn.TBN * normal);

	float bias = max(0.05 * (1.0 - dot(normal, mainLight.direction.xyz)), 0.005);
	float shadow = calculateShadow(RESurfaceDataIn.lightSpacePosition, bias);
	vec3 ambient = vec3(0.1);


	vec3 diffuse = calculateDiffuse(normal);

	vec3 lighting =  ((diffuse + ambient) * terrainColor);

	return vec4(lighting, 1.0);








}


