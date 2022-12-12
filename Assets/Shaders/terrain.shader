#shader shared
struct Material
{
    vec4 ambient;
}
#shader vertex
vec4 vertex(REVertexData IN)
{

	mat4 objectToWorld_T = transpose(OBJECT_TO_WORLD);

	vec4 worldSpace = objectToWorld_T * vec4(IN.position, 1.0);
	vec4 worldNormal = transpose(inverse(objectToWorld_T)) * vec4(IN.normal, 1.0);
	vec4 worldTangent = objectToWorld_T * vec4(IN.tangent, 1.0);
	RESurfaceDataOut.TBN = calculateTBN(worldTangent.xyz, worldNormal.xyz);
	//RESurfaceDataOut.material = IN.material;
	RESurfaceDataOut.objectId = IN.objectId;
	RESurfaceDataOut.posCS = u_vp * worldSpace;
	RESurfaceDataOut.posWS = vec3(worldSpace);
	RESurfaceDataOut.texCoord = IN.texCoord;
	RESurfaceDataOut.normal = worldNormal.xyz;
	RESurfaceDataOut.lightSpacePosition = lightSpaceMatrix * worldSpace;
	RESurfaceDataOut.eyeSpacePosition = u_view * worldSpace;
	return RESurfaceDataOut.posCS;
}
#shader fragment
vec4 fragment()
{
    return vec4(SAMPLE_TEXTURE(ambient,RESurfaceDataIn.texCoord).rgb,1.0);
}