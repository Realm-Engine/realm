struct DirectionalLight
{
        vec4 direction;
        vec4 color;
};
layout(std140, binding = 0) uniform _reGloblaData
{
	mat4 u_vp;
    DirectionalLight mainLight;
        

};

struct REVertexData
{
	vec3 position;
	vec2 texCoord;
	vec3 normal;
	ObjectData objectData;
	int objectId;
	vec3 tangent;

};

layout (std430,binding = 1) buffer _perObjectData
{
	ObjectData data[];
};




mat3 calculateTBN()
{
	vec3 T = normalize(v_Tangent);
	vec3 N = normalize(v_Normal);
	vec3 B = normalize(cross(N,T));
	return mat3(T,B,N);


}


vec2 samplerUV(vec4 to)
{
	return (v_TexCoord * vec2(to.x,to.y)) + vec2(to.z,to.w);
}

uniform sampler2D atlasTextures[16];

#define objectTexture atlasTextures[gl_DrawID]