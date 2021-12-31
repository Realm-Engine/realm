
#version 460 core

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

struct ObjectData
{
	vec4 color;
	float oceanLevel;
};

layout (std430,binding = 1) buffer _perObjectData
{
	ObjectData data[];
};
layout(location = 0) uniform sampler2D screenTexture;
layout(location = 1) uniform sampler2D depthTexture;
uniform sampler2D atlasTextures[16];

out vec4 outColor; 
in vec4 Color;
in RESurfaceData
{
	vec3 posWS;
	vec4 posCS;
	vec2 texCoord;
	flat int objectId;
	ObjectData objectData;
	vec3 normal;
	mat3 TBN;

} RESurfaceDataIn;


vec3 grayToNormal(sampler2D grayTexture,vec2 uv,float delta)
{
	vec2 dx = uv + vec2(delta,0);
	vec2 dy = uv + vec2(0,delta);
	vec4 graySample = texture(grayTexture,uv);
	vec4 sampleX = texture(grayTexture,dx);
	vec4 sampleY = texture(grayTexture,dy);
	float ab = graySample.x-sampleX.x;
	float ac = graySample.x-sampleY.x;
	return cross(vec3(1,0,ab),vec3(0,1,ac));

}



vec2 samplerUV(vec4 to)
{
	return (RESurfaceDataIn.texCoord * vec2(to.x,to.y)) + vec2(to.z,to.w);
}

void main()
{ 
	outColor = RESurfaceDataIn.objectData.color;
	outColor.w = 0.5f;
	
}