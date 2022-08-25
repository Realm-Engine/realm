#shader shared
struct Material {
	vec4 color;
};


#shader vertex screenVertex
vec4 vertex(REVertexData IN)
{
	mat4 vp = u_projection * u_view;
	RESurfaceDataOut.TBN = calculateTBN();
	RESurfaceDataOut.material = IN.material;
	RESurfaceDataOut.objectId = IN.objectId;
	vec4 position = vec4(IN.position, 1.0);
	RESurfaceDataOut.posCS = vp * position;
	RESurfaceDataOut.posWS = IN.position;
	RESurfaceDataOut.texCoord = IN.texCoord;
	RESurfaceDataOut.normal = IN.normal;
	RESurfaceDataOut.lightSpacePosition = lightSpaceMatrix * vec4(IN.position, 1.0);
	RESurfaceDataOut.eyeSpacePosition = u_view * vec4(IN.position, 1.0);
	return RESurfaceDataOut.posCS;
}

#shader fragment screenFragment
vec4 fragment()
{
	vec4 color = vec4(normalize(getObjectData(color).rgb), getObjectData(color).a);
	return texture(cameraScreenTexture,RESurfaceDataIn.texCoord);

}



