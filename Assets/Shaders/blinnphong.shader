#shader shared
struct Material
{
	vec4 ambient;
	vec4 diffuse;
	vec4 normal;
	vec4 specular;
	float shininess;
	float padding2;
};


#shader vertex blinn-phong-vertex
vec4 vertex(REVertexData IN)
{

	vec4 worldSpace = OBJECT_TO_WORLD_T * vec4(IN.position, 1.0);
	vec4 worldNormal = transpose(inverse(OBJECT_TO_WORLD_T)) * vec4(IN.normal, 1.0);
	vec4 worldTangent = OBJECT_TO_WORLD_T * vec4(IN.tangent, 1.0);
	RESurfaceDataOut.TBN = calculateTBN(worldTangent.xyz, worldNormal.xyz);
	RESurfaceDataOut.material = IN.material;
	RESurfaceDataOut.objectId = IN.objectId;
	RESurfaceDataOut.posCS = u_vp * worldSpace;
	RESurfaceDataOut.posWS = vec3(worldSpace);
	RESurfaceDataOut.texCoord = IN.texCoord;
	RESurfaceDataOut.normal = worldNormal.xyz;
	RESurfaceDataOut.lightSpacePosition = lightSpaceMatrix * worldSpace;
	RESurfaceDataOut.eyeSpacePosition = u_view * worldSpace;
	return RESurfaceDataOut.posCS;
}
#shader fragment blinn-phong-fragment



float lambertAmount(vec3 normal)
{
	float amount = max(dot(normal, vec3(-mainLight.direction)), 0.0);
	return amount;
}

float specularAmount(vec3 normal, vec3 viewDir, vec3 matSpecularColor, float shininess)
{
	vec3 reflectDir = reflect(-mainLight.direction.xyz, normal);
	float specAngle = max(dot(viewDir, reflectDir), 0.0);
	
	return pow(specAngle, shininess/4.0);
}


vec4 fragment()
{
	vec3 ambient = getObjectData(ambient).rgb;
	vec3 normal = SAMPLE_TEXTURE(normal, RESurfaceDataIn.texCoord).rgb;
	normal = normalize(RESurfaceDataIn.TBN * normal);
	vec4 diffuse = SAMPLE_TEXTURE(diffuse, RESurfaceDataIn.texCoord);
	vec3 specular = SAMPLE_TEXTURE(specular, RESurfaceDataIn.texCoord).rgb;
	float shininess = getObjectData(shininess);
	

	float lambert = lambertAmount(normal);
	
	float spec = 0.0;
	if (lambert > 0.0)
	{
		spec = specularAmount(normal, normalize(camera.direction.xyz), specular, shininess);

	}
	
	float bias = max(0.05 * (1.0 - dot(normal, mainLight.direction.xyz)), 0.005);
	float shadow = calculateShadow(RESurfaceDataIn.lightSpacePosition, bias);
	
	
	return vec4(((lambert * diffuse.rgb) + (spec * specular)) * (ambient + 1- shadow), 1.0);


}