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

	vec4 worldSpace = OBJECT_TO_WORLD_T * vec4(IN.position, 1.0);
	vec4 worldNormal = transpose(inverse(OBJECT_TO_WORLD_T)) * vec4(IN.normal, 1.0);
	vec4 worldTangent = OBJECT_TO_WORLD_T * vec4(IN.tangent, 1.0);
    RESurfaceDataOut.TBN = calculateTBN(worldTangent.xyz,worldNormal.xyz);
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

	vec3 ambient = vec3(0.2);
	vec3 normal = SAMPLE_TEXTURE(normal, RESurfaceDataIn.texCoord).rgb;
	normal = normalize(RESurfaceDataIn.TBN * normal);
	
	
	vec3 r = reflect(vec3(camera.direction), normalize(normal));
	vec3 env = vec3(texture(envSkybox, r));
	vec4 color = SAMPLE_TEXTURE(diffuse, RESurfaceDataIn.texCoord);
	vec3 lighting = calculateLighting(normal,ambient);
	float bias = max(0.05 * (1.0 - dot(normal, mainLight.direction.xyz)), 0.005);
	float shadow = calculateShadow(RESurfaceDataIn.lightSpacePosition, bias);
	
	
	float fog = abs(RESurfaceDataIn.eyeSpacePosition.z / RESurfaceDataIn.eyeSpacePosition.w);
	fog = 1.0 - clamp(exp(-0.1 * fog),0.0,1.0);

	vec3 frag = (ambient + (1-shadow)) *  (color.rgb * lighting);
	//frag = mix(vec4(frag, 1.0), vec4(0.1, 0.1, 0.1, 1.0), fog).rgb;
	return vec4(frag, 1.0) * getObjectData(color);
}