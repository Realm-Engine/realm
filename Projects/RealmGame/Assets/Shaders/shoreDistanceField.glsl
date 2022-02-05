#version 430
layout(local_size_x = 1, local_size_y = 1) in;
layout(rgba8, binding = 0) uniform image2D climateData;
layout(r8,binding = 1) uniform image2D seeds;
layout(location = 0) uniform int u_stepsize;

float sampleMoisture(ivec2 uv)
{
	return imageLoad(climateData,uv).g;

}

float sampleDistance(ivec2 uv)
{
	return imageLoad(climateData,uv).b;

}

void floodJump()
{
	ivec2 coord = ivec2(gl_GlobalInvocationID.xy);
	vec4 climate = imageLoad(climateData,coord);
	ivec2 propogation[9] = ivec2[9](ivec2(0),ivec2(0),ivec2(0),ivec2(0),ivec2(0),ivec2(0),ivec2(0),ivec2(0),ivec2(0));
	int p = 0;
	for(int x = -1; x <= 1; x++)
	{
		for(int y = -1; y <= 1; y++)
		{
			propogation[p] = ivec2(coord.x + (x * u_stepsize), coord.y + (y*u_stepsize));
			p++;
		
		}
		imageStore(seeds,propogation[p-1],vec4(1.0));
	}
	float isSeed = step(1.0,imageLoad(seeds,coord).r);
	float currentMoisture = sampleMoisture(coord);

	
	if(isSeed == 1)
	{
		
		for(int j = 0; j < propogation.length; j++)
		{
			if(propogation[j] != coord )
			{
				vec4 propogationClimate = imageLoad(climateData,propogation[j]);
				float moistureSample = propogationClimate.g;

				float distance = distance(propogation[j],coord) /255;
				float distanceSample = propogationClimate.b;

				if(moistureSample > 0 )
				{
					if(climate.b == 0.0 )
					{
						imageStore(climateData,coord,vec4(climate.r,climate.g,distance ,climate.a));
					}
					
					if(distance < climate.b)
					{
						imageStore(climateData,coord,vec4(climate.r,climate.g,distance ,climate.a));
	
					}

				
				}
				
				if(moistureSample == 0.0)
				{
					if(distanceSample == 0.0)
					{
						imageStore(climateData,propogation[j],vec4(propogationClimate.r,propogationClimate.g,distance  + climate.b,propogationClimate.a));
					
					}
					if(climate.g == 1.0)
					{
						if(distanceSample > distance)
						{
							imageStore(climateData,propogation[j],vec4(propogationClimate.r,propogationClimate.g,distance ,propogationClimate.a));
						
						}
					
					}
				}
			}
		
		}
	}
}

void simple()
{
	vec2 size = imageSize(climateData);
	ivec2 coord = ivec2(gl_GlobalInvocationID.xy);
	ivec2 pos = coord + ivec2(0,u_stepsize);
	ivec2 neg = coord + ivec2(0,u_stepsize);
	float closestMoisture = max(sampleMoisture(pos),sampleMoisture(neg));
	float closestEdge = max(sampleDistance(pos),sampleDistance(neg));
	vec4 climate = imageLoad(climateData,coord);
	float distance = distance(coord,pos) / 255 ;
	imageStore(climateData,coord,vec4(climate.r,climate.g, max(distance, climate.b) * closestMoisture,climate.a));
	
	



}

void main()
{
	simple();
	
	
}
