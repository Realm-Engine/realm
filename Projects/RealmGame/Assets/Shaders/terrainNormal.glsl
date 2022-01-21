
#version 430
layout(local_size_x = 1, local_size_y = 1) in;
layout(rgba8, binding = 0) writeonly uniform image2D imgOutput;
layout(rgba8, binding = 1) readonly uniform image2D imgHeight;

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
	imageStore(imgOutput,uv,vec4(result,1));
}

void main()
{
	grayToNormal(ivec2(gl_GlobalInvocationID.xy),14);
}