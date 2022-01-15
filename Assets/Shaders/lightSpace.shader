#shader shared
struct Material
{
	vec4 color;
};


#shader vertex lightSpaceVertex
vec4 vertex(REVertexData IN)
{
	RESurfaceDataOut.TBN = calculateTBN();
	RESurfaceDataOut.material = IN.material;
	RESurfaceDataOut.objectId = IN.objectId;
	RESurfaceDataOut.posCS = u_vp * vec4(IN.position, 1.0);
	RESurfaceDataOut.posWS = IN.position;
	RESurfaceDataOut.texCoord = IN.texCoord;
	RESurfaceDataOut.normal = IN.normal;
	RESurfaceDataOut.lightSpacePosition = lightSpaceMatrix * vec4(IN.position, 1.0);
	return RESurfaceDataOut.posCS;
}
#shader fragment lightSpaceFragment




vec4 fragment()
{

	
	vec4 color = getObjectData(color);
	return color;
}