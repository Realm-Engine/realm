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



vec3 lambertianDiffuse(vec3 normal)
{
	float amount = max(dot(normal), vec3(-mainLight.direction), 0.0);
	return amount * mainLight.color.rgb;
}

float specularAmount(vec3 normal, vec3 dirToViewer, vec3 matSpecularColor, float shininess)
{
	vec3 r = reflect(-mainLight.direction.xyz, normalize(normal));
	return pow(max(dot(dirToViewer, r), 0.0), shininess);
}


vec4 fragment()
{
	vec3 ambient = getObjectData(ambient).rgb;
	vec3 normal = SAMPLE_TEXTURE(normal, RESurfaceDataIn.texCoord).rgb;
	vec4 diffuse = SAMPLE_TEXTURE(diffuse, RESurfaceDataIn.texCoord).rgb;
	vec3 specular = SAMPLE_TEXTURE(specular, RESurfaceDataIn.texCoord).rgb;
	float shininess = getObjectData(shininess);
	

	vec3 lambert = lambertianDiffuse(normal);
	float spec = specularAmount(normal, (camera.position.xyz - RESurfaceDataIn.posWS), specular, shininess);
	return vec4(diffuse.rgb + (lambert + ambient) + vec3(spec), diffuse.a);


}