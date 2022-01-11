#shader shared
struct Material
{
	vec4 color;
	vec4 diffuse;
	vec4 normal;
	float specularPower;
	float padding1;
	float shinyness;
	float padding2;
};


#shader vertex simpleVertex
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
#shader fragment simpleFragment



vec3 calculateLighting(vec3 normal,vec3 ambient)
{
	vec3 diffuse = calculateDiffuse(normal);
	vec3 specular = calculateSpecular(normal, RESurfaceDataIn.posWS, getObjectData(specularPower), getObjectData(shinyness));
	vec3 lighting = diffuse + specular + ambient;
	return lighting;

}


vec4 fragment()
{

	vec3 ambient = vec3(0.1);
	vec3 normal = SAMPLE_TEXTURE(normal, RESurfaceDataIn.texCoord).rgb;
	normal = transformNormal(normal);
	vec4 color = SAMPLE_TEXTURE(diffuse, RESurfaceDataIn.texCoord);
	vec3 lighting = calculateLighting(normal,ambient);
	float bias = max(0.05 * (1.0 - dot(normal, mainLight.direction.xyz)), 0.005);
	float shadow = calculateShadow(RESurfaceDataIn.lightSpacePosition, bias);
	
	vec3 frag = (ambient + (1-shadow)) *  (color.rgb * lighting);
	return vec4(frag, color.a);
}