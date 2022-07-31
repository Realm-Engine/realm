#shader shared 
struct Material
{
	vec4 color;
};


#shader vertex debugVertex
vec4 vertex(REVertexData IN)
{
	mat4 vp = u_projection * u_view;
	RESurfaceDataOut.TBN = calculateTBN();
	RESurfaceDataOut.material = IN.material;
	RESurfaceDataOut.objectId = IN.objectId;
	RESurfaceDataOut.posCS = vp * vec4(IN.position, 1.0);
	RESurfaceDataOut.posWS = IN.position;
	RESurfaceDataOut.texCoord = IN.texCoord;
	RESurfaceDataOut.normal = IN.normal;
	RESurfaceDataOut.lightSpacePosition = lightSpaceMatrix * vec4(IN.position, 1.0);
	RESurfaceDataOut.eyeSpacePosition = u_view * vec4(IN.position, 1.0);
	return RESurfaceDataOut.posCS;
}

#shader fragment debugFragment
vec4 fragment()
{
	return vec4(getObjectData(color).rgb,1.0);

}