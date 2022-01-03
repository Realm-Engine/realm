#shader shared
struct ObjectData
{
    float cameraFar;
    float cameraNear;
};
#shader vertex simpleVertex
vec4 vertex(REVertexData IN)
{
    RESurfaceDataOut.TBN = calculateTBN();
	RESurfaceDataOut.objectData = IN.objectData;
	RESurfaceDataOut.objectId = IN.objectId;
	RESurfaceDataOut.posCS = transpose(u_vp) * vec4(v_Position, 1.0);
	RESurfaceDataOut.posWS = v_Position;
	RESurfaceDataOut.texCoord = IN.texCoord;
	RESurfaceDataOut.normal = IN.normal;
	return RESurfaceDataOut.posCS;
}
#shader fragment simpleFragment



vec4 fragment()
{
    float dist = RESurfaceDataIn.posWS.z / RESurfaceDataIn.objectData.cameraFar;
    return vec4(dist,dist,dist,1.0);
}