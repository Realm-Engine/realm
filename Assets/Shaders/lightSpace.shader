#shader shared
struct Material
{
	vec4 color;
};


#shader vertex lightSpaceVertex
vec4 vertex(REVertexData IN)
{
	vec4 worldSpace = OBJECT_TO_WORLD_T * vec4(IN.position, 1.0);
	vec4 worldNormal = transpose(inverse(OBJECT_TO_WORLD_T)) * vec4(IN.normal, 1.0);
	vec4 worldTangent = OBJECT_TO_WORLD_T * vec4(IN.tangent, 1.0);
	
	
	RESurfaceDataOut.TBN = calculateTBN(worldNormal.xyz, worldTangent.xyz);
	//RESurfaceDataOut.material = IN.material;
	RESurfaceDataOut.objectId = IN.objectId;
	RESurfaceDataOut.posCS = lightSpaceMatrix * worldSpace;
	RESurfaceDataOut.posWS = IN.position;
	RESurfaceDataOut.texCoord = IN.texCoord;
	RESurfaceDataOut.normal = IN.normal.xyz;
	/*RESurfaceDataOut.lightSpacePosition = lightSpaceMatrix * worldSpace;
	RESurfaceDataOut.eyeSpacePosition = u_view * worldSpace;*/
	return RESurfaceDataOut.posCS;
}
#shader fragment lightSpaceFragment




vec4 fragment()
{

	
	vec4 color = getObjectData(color);
	return color;
}