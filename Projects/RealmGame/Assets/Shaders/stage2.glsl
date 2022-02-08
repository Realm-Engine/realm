
#version 430
layout(local_size_x = 1, local_size_y = 1) in;
layout(rgba8, binding = 0) writeonly uniform image2D imgOutput;
layout(rgba8, binding = 1) readonly uniform image2D imgHeight;
layout(rgba8, binding = 2) uniform image2D climateData;
layout(location = 0) uniform float heightStrength;

layout(std430, binding = 3) writeonly buffer _tileData
{
	
	float tileData[1];

};

void grayToNormal(ivec2 uv,float delta)
{
	ivec2 dx = uv + ivec2(delta,0);
	ivec2 dy = uv + ivec2(0,delta);
	vec4 graySample = imageLoad(imgHeight,uv);
	vec4 sampleX = imageLoad(imgHeight,dx);
	vec4 sampleY = imageLoad(imgHeight,dy);
	float ab = graySample.x-sampleX.x;
	float ac = graySample.x-sampleY.x;
	vec3 result = cross(vec3(1,0,ab),vec3(0,1,ac));
	imageStore(imgOutput,uv,vec4(result,graySample.r));
}

void blurOcean()
{
	vec2 size = imageSize(climateData);
	float offset[5] = float[](0.0, 1.0, 2.0, 3.0, 4.0);
	float weight[5] = float[](0.2270270270, 0.1945945946, 0.1216216216,
                                  0.0540540541, 0.0162162162);
	ivec2 coord = ivec2(gl_GlobalInvocationID.xy);
	vec4 climate = imageLoad(climateData,coord);
	
	float heat = climate.r;
	int passes = int(mix(3,9,heat));
	for(int j = 1; j < 9;j++)
	{
		float moisture = climate.g * weight[0];
		for(int i = 1; i < 5; i++)
		{
			moisture += imageLoad(climateData,coord + ivec2(0.0,offset[i]  )).g * (weight[i] );
			
			moisture += imageLoad(climateData,coord - ivec2(0.0,offset[i] )).g *  (weight[i] );
		
		}

	
		imageStore(climateData,coord,vec4(climate.r,moisture,climate.b,climate.a));
	}

	

}

float sampleMoisture(ivec2 coords)
{
	return imageLoad(climateData,coords).g;

}

void distToOcean()
{
	float distance = 0;

	


}

void main()
{
	grayToNormal(ivec2(gl_GlobalInvocationID.xy),10);
	tileData[0] = 1.0f;
	
	//blurOcean();
	
	
}