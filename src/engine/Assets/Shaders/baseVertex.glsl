out RESurfaceData
{
	vec3 posWS;
	vec4 posCS;
	vec2 texCoord;
	flat int objectId;
	ObjectData objectData;
	vec3 normal;
	mat3 TBN;

} RESurfaceDataOut;

void main()
{
	REVertexData vertexData;
	vertexData.tangent = v_Tangent;
	vertexData.position = v_Position;
	vertexData.texCoord = v_TexCoord;
	vertexData.normal = v_Normal;
	vertexData.objectData = data[gl_DrawID];
	vertexData.objectId = gl_DrawID;
	gl_Position = vert(vertexData);
	
}