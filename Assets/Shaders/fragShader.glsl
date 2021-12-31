
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
	vec4 heightMap;
	float heightStrength;
	float oceanLevel;
};

layout (std430,binding = 1) buffer _perObjectData
{
	ObjectData data[];
};
layout(location = 0) uniform sampler2D screenTexture;
layout(location = 1) uniform sampler2D depthTexture;
uniform sampler2D atlasTextures[16];

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

vec3 calculateDiffuse(vec3 normal)
{
	float amount = max(dot(normal,vec3(normalize(-mainLight.direction))),0.0);
	return amount * vec3(mainLight.color);

}

vec4 frag()
{
	float height = texture(atlasTextures[RESurfaceDataIn.objectId],samplerUV(RESurfaceDataIn.objectData.heightMap)).x;
	float difference = abs(height - RESurfaceDataIn.objectData.oceanLevel);
	vec4 terrainColor= vec4(1 - difference,1.0,0.1,1.0);

	//outColor = vec4(height,1-height,0,1.0);
	vec3 normal = grayToNormal(atlasTextures[RESurfaceDataIn.objectId],samplerUV(RESurfaceDataIn.objectData.heightMap),0.0071358);
    normal = normal * 2.0 + 1;
	return vec4(calculateDiffuse(normal),1.0) * terrainColor;


}


out vec4 FragColor; 

void main()
{ 
	FragColor = frag();
}