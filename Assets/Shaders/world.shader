#shader shared

struct ObjectData
{
	vec4 heightMap;
	float heightStrength;
	float oceanLevel;
};

#shader vertex worldVertex
vec4 vertex(REVertexData IN)
{
	
	vec4 heightSample =texture(objectTexture,samplerUV(IN.objectData.heightMap,IN.texCoord));
	float height = (heightSample.x);
	height = height * IN.objectData.heightStrength;
	vec3 position = v_Position + vec3(0,height,0);
	RESurfaceDataOut.TBN = calculateTBN();
	RESurfaceDataOut.objectData = IN.objectData;
	RESurfaceDataOut.objectId = IN.objectId;
	RESurfaceDataOut.posCS = transpose(u_vp) * vec4(position, 1.0);
	RESurfaceDataOut.posWS = position;
	RESurfaceDataOut.texCoord = IN.texCoord;
	RESurfaceDataOut.normal = IN.normal;
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
	float height = texture(objectTexture,samplerUV(RESurfaceDataIn.objectData.heightMap,RESurfaceDataIn.texCoord)).x;
	float difference = abs(height - RESurfaceDataIn.objectData.oceanLevel);
	vec4 terrainColor= vec4(1 - difference,1.0,0.1,1.0);

	//outColor = vec4(height,1-height,0,1.0);
	vec3 normal = grayToNormal(objectTexture,samplerUV(RESurfaceDataIn.objectData.heightMap,RESurfaceDataIn.texCoord),0.0071358);
    normal = normal * 2.0 + 1;
	return vec4(calculateDiffuse(normal),1.0) * terrainColor;


}

