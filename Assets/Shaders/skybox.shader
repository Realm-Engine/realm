#shader shared
struct Material
{
	float exposure;
};


#shader vertex skyboxVertex
vec4 vertex(REVertexData IN)
{
	mat4 vp = u_vp;
	
	RESurfaceDataOut.material = IN.material;
	RESurfaceDataOut.objectId = IN.objectId;
	RESurfaceDataOut.posCS = vec4(IN.position, 1.0);
	RESurfaceDataOut.posWS = IN.position;
	RESurfaceDataOut.texCoord = IN.texCoord;
	RESurfaceDataOut.normal = IN.normal;
	RESurfaceDataOut.lightSpacePosition = lightSpaceMatrix * vec4(IN.position, 1.0);
	RESurfaceDataOut.eyeSpacePosition =vec4(mat3(vp) * IN.position,1.0);
	return RESurfaceDataOut.posCS;
}
#shader fragment skyboxFragment


vec4 fragment()
{
	return texture(envSkybox, vec3(normalize(RESurfaceDataIn.eyeSpacePosition)));
}