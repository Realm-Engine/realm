#shader shared
struct ObjectData
{
	vec4 color;
	vec4 diffuse;
};
#shader vertex simpleVertex
vec4 vertex(REVertexData IN)
{
    RESurfaceDataOut.TBN = calculateTBN();
	RESurfaceDataOut.objectData = IN.objectData;
	RESurfaceDataOut.objectId = IN.objectId;
	RESurfaceDataOut.posCS = u_vp * vec4(v_Position, 1.0);
	RESurfaceDataOut.posWS = v_Position;
	RESurfaceDataOut.texCoord = IN.texCoord;
	RESurfaceDataOut.normal = IN.normal;
	return RESurfaceDataOut.posCS;
}
#shader fragment simpleFragment



vec4 fragment()
{
	vec3 lighting =  calculateDiffuse(RESurfaceDataIn.normal, vec3(0.25)) * 0.3 ;
	vec3 color = getObjectData(color).rgb;
	return vec4(color * lighting,1.0);
}