#shader shared
struct ObjectData
{
	vec4 color;
};
#shader vertex simpleVertex
vec4 vertex(REVertexData IN)
{
    RESurfaceDataOut.TBN = calculateTBN();
	RESurfaceDataOut.objectData = IN.objectData;
	RESurfaceDataOut.objectId = IN.objectId;
	RESurfaceDataOut.posCS = u_vp * vec4(IN.position, 1.0);
	RESurfaceDataOut.posWS = v_Position;
	RESurfaceDataOut.texCoord = IN.texCoord;
	RESurfaceDataOut.normal = IN.normal;
	RESurfaceDataOut.lightSpacePosition = lightSpaceMatrix * vec4(IN.position, 1.0);
	return RESurfaceDataOut.posCS;
}
#shader fragment simpleFragment



vec4 fragment()
{
	vec3 ambient = vec3(0.25);
	vec3 lighting =  calculateDiffuse(RESurfaceDataIn.normal, ambient) * 0.3 ;
	float bias = max(0.05 * (1.0 - dot(RESurfaceDataIn.normal, mainLight.direction.xyz)), 0.005);
	float shadow = calculateShadow(RESurfaceDataIn.lightSpacePosition, 0.005);
	vec3 color = getObjectData(color).rgb;
	vec3 frag = (ambient + (1.0 - shadow)) * (color * lighting);
	return vec4(frag, 1.0);
}