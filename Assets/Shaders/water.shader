#shader shared
struct ObjectData
{
	vec4 color;
	float oceanLevel;
};
#shader vertex waterVertex
vec4 vertex(REVertexData IN)
{
	float oceanLevel = IN.objectData.oceanLevel;
	vec3 position = IN.position + vec3(0,oceanLevel,0);

	RESurfaceDataOut.TBN = calculateTBN();
	RESurfaceDataOut.objectData = IN.objectData;
	RESurfaceDataOut.objectId = IN.objectId;
	RESurfaceDataOut.posCS = transpose(u_vp) * vec4(position, 1.0);
	RESurfaceDataOut.posWS = v_Position;
	RESurfaceDataOut.texCoord = IN.texCoord;
	RESurfaceDataOut.normal = IN.normal;
	return RESurfaceDataOut.posCS;

}

#shader fragment waterFragment
vec4 fragment()
{
	vec4 color = RESurfaceDataIn.objectData.color;
	color.w = 0.6f;
	return color;
}