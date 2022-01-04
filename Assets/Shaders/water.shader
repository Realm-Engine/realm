#shader shared
#define OBJECT_DATA
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
	RESurfaceDataOut.posCS = u_vp * vec4(position, 1.0);
	RESurfaceDataOut.posWS = v_Position;
	RESurfaceDataOut.texCoord = IN.texCoord;
	RESurfaceDataOut.normal = IN.normal;
    RESurfaceDataOut.lightSpacePosition = lightSpaceMatrix * vec4(position,1.0);
	return RESurfaceDataOut.posCS;

}

#shader fragment waterFragment
vec4 fragment()
{
	vec4 color = RESurfaceDataIn.objectData.color;
	float bias = max(0.05 * (1.0 - dot(RESurfaceDataIn.normal, -mainLight.direction.xyz)), 0.005);
	float shadow = calculateShadow(RESurfaceDataIn.lightSpacePosition,bias);
	vec3 lighting = (vec3(1) + (1.0 - shadow)) *   color.xyz;
	
	return vec4(lighting,1.0);
}