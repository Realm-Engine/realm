#shader shared
struct ObjectData
{
	vec4 color;
	float specularPower;
	float padding1;
	float shinyness;
	float padding2;
};
#shader vertex simpleVertex
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
#shader fragment simpleFragment



vec4 fragment()
{

	vec3 ambient = vec3(0.1);
	vec3 diffuse = calculateDiffuse(RESurfaceDataIn.normal) * 0.3;
	vec3 specular = calculateSpecular(RESurfaceDataIn.normal, RESurfaceDataIn.posWS,getObjectData(specularPower), getObjectData(shinyness));
	vec3 lighting =  diffuse + specular + ambient ;
	float bias = max(0.05 * (1.0 - dot(RESurfaceDataIn.normal, mainLight.direction.xyz)), 0.005);
	float shadow = calculateShadow(RESurfaceDataIn.lightSpacePosition, 0.005);
	vec3 color = getObjectData(color).rgb;
	vec3 frag = (color * lighting);
	return vec4(frag, 1.0);
}