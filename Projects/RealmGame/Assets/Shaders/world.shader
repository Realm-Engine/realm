#shader shared

struct Material
{
	vec4 heightMap;
	vec4 normalMap;
	float heightStrength;
	float packing1;
	float oceanLevel;
	float height;
};



#shader vertex worldVertex
vec4 vertex(REVertexData IN)
{
	
	vec4 heightSample =texture(objectTexture,samplerUV(IN.material.heightMap,IN.texCoord));
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
	float height = getObjectData(height);
	float dist = distance(height, getObjectData(oceanLevel));
	float difference = abs(height - getObjectData(oceanLevel));

	vec3 terrainColor = mix(normalize(vec3(177, 185, 40)), normalize(vec3(25, 93, 0)), dist);

	//outColor = vec4(height,1-height,0,1.0);
	vec3 normal = SAMPLE_TEXTURE(normalMap, RESurfaceDataIn.texCoord).rgb;
	normal = normal * 2;
	normal = normalize(RESurfaceDataIn.TBN * normal);

	float bias = max(0.05 * (1.0 - dot(normal, mainLight.direction.xyz)), 0.005);
	float shadow = calculateShadow(RESurfaceDataIn.lightSpacePosition,bias);
	vec3 ambient = vec3(0.1);
	
	
	vec3 diffuse = calculateDiffuse(normal);
	
	vec3 lighting = (ambient + (1.0 - shadow)) *  (( diffuse  + ambient) * terrainColor);
	return vec4(lighting, 1.0);
	
	




}


