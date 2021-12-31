#shader vertex
vec4 vert(REVertexData IN)
{
	
	vec4 heightSample =texture(objectTexture,samplerUV(IN.objectData.heightMap));
	float height = (heightSample.x);
	height = height * IN.objectData.heightStrength;
	vec3 position = v_Position + vec3(0,height,0);
	RESurfaceDataOut.TBN = calculateTBN();
	RESurfaceDataOut.objectData = IN.objectData;
	RESurfaceDataOut.objectId = IN.objectId;
	RESurfaceDataOut.posCS = transpose(u_vp) * vec4(position, 1.0);
	RESurfaceDataOut.posWS = position;
	RESurfaceDataOut.texCoord = IN.texCoord;
	RESurfaceDataOut.normal = IN.normal;
	return RESurfaceDataOut.posCS;
	


}

#shader frag
