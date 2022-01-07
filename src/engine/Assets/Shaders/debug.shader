#shader shared 
struct ObjectData
{
	vec4 color;
};


#shader vertex debugVertex
vec4 vertex(REVertexData IN)
{
	RESurfaceDataOut.TBN = calculateTBN();
	RESurfaceDataOut.objectData = IN.objectData;
	RESurfaceDataOut.objectId = IN.objectId;
	RESurfaceDataOut.posCS = u_vp * vec4(IN.position, 1.0);
	RESurfaceDataOut.posWS = IN.position;
	RESurfaceDataOut.texCoord = IN.texCoord;
	RESurfaceDataOut.normal = IN.normal;
	RESurfaceDataOut.lightSpacePosition = lightSpaceMatrix * vec4(IN.position, 1.0);
	return RESurfaceDataOut.posCS;
}

#shader fragment debugFragment
vec4 fragment()
{
	return vec4(getObjectData(color).rgb,1.0);

}