#shader shared
struct Material
{
	vec4 color;
};


#shader vertex depthPrepassvertex
vec4 vertex(REVertexData IN)
{
	mat4 vp = transpose(u_projection * u_view);
	RESurfaceDataOut.TBN = calculateTBN();
	RESurfaceDataOut.material = IN.material;
	RESurfaceDataOut.objectId = IN.objectId;
	RESurfaceDataOut.posCS = vp * vec4(IN.position, 1.0);
	RESurfaceDataOut.posWS = IN.position;
	RESurfaceDataOut.texCoord = IN.texCoord;
	RESurfaceDataOut.normal = IN.normal;
	RESurfaceDataOut.lightSpacePosition = lightSpaceMatrix * vec4(IN.position, 1.0);
	RESurfaceDataOut.eyeSpacePosition = u_view * vec4(IN.position, 1.0);
	return RESurfaceDataOut.posCS;
}
#shader fragment depthPreepassFragment




vec4 fragment()
{


	vec4 color = getObjectData(color);
	return color;
}