
#shader shared
struct Material {
	vec4 color;
	vec4 fontTexture;


};


#shader vertex textVertex
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

#shader fragment textFragment
vec4 fragment()
{
	vec4 color = vec4(normalize(getObjectData(color).rgb), getObjectData(color).a);
	return vec4(color.rgb, SAMPLE_TEXTURE(fontTexture, RESurfaceDataIn.texCoord).r * color.a);

}



