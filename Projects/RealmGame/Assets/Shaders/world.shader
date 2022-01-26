#shader shared

struct Material
{
	vec4 normalHeightMap;
	vec4 terrainDataMap;
	float heightStrength;
	float packing1;
	float oceanLevel;
	float height;
};





#shader vertex worldVertex
vec4 vertex(REVertexData IN)
{
	
	float heightSample = SAMPLE_TEXTURE(normalHeightMap, IN.texCoord).a;
	float height = (heightSample.x) * getObjectData(heightStrength);
	IN.material.height = height;
	vec3 position = v_Position + vec3(0,height,0);
	RESurfaceDataOut.TBN = calculateTBN();
	RESurfaceDataOut.material = IN.material;
	RESurfaceDataOut.objectId = IN.objectId;
	RESurfaceDataOut.posCS = u_vp * vec4(position, 1.0);
	RESurfaceDataOut.posWS = position;
	RESurfaceDataOut.texCoord = IN.texCoord;
	RESurfaceDataOut.normal = IN.normal;
	RESurfaceDataOut.lightSpacePosition = lightSpaceMatrix * vec4(position,1.0);
	
	return RESurfaceDataOut.posCS;
	


}

#shader fragment worldFragment


vec3 grayToNormal(sampler2D grayTexture,vec2 uv,float delta)
{
	vec2 dx = uv + vec2(delta,0);
	vec2 dy = uv + vec2(0,delta);
	vec4 graySample = texture(grayTexture,uv);
	vec4 sampleX = texture(grayTexture,dx);
	vec4 sampleY = texture(grayTexture,dy);
	float ab = graySample.x-sampleX.x;
	float ac = graySample.x-sampleY.x;
	return cross(vec3(1,0,ab),vec3(0,1,ac));

}



vec4 fragment()
{

	
	vec4 terrainData = SAMPLE_TEXTURE(terrainDataMap, RESurfaceDataIn.texCoord);
	vec3 terrainColor = terrainData.rgb;
	float border = 1 - terrainData.a;
	//terrainColor *= border;
	float gamma = 2.2;
	terrainColor = pow(terrainColor, vec3(2.2));
	//outColor = vec4(height,1-height,0,1.0);
	vec3 normal = SAMPLE_TEXTURE(normalHeightMap, RESurfaceDataIn.texCoord).rgb;
	normal = normal * 2;
	normal = normalize(RESurfaceDataIn.TBN * normal);

	float bias = max(0.05 * (1.0 - dot(normal, mainLight.direction.xyz)), 0.005);
	float shadow = calculateShadow(RESurfaceDataIn.lightSpacePosition,bias);
	vec3 ambient = vec3(0.1);
	
	
	vec3 diffuse = calculateDiffuse(normal);
	
	vec3 lighting = (( diffuse  + ambient) * terrainColor);

	return vec4(vec3(lighting), 1.0);
	
	
	
	




}


