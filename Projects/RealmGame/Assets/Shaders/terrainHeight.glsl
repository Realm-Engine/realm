
#version 430
layout(local_size_x = 1, local_size_y = 1) in;
layout(rgba8, binding = 0) writeonly uniform image2D img_output;
layout(location = 0) uniform float u_seed;


float rand(vec2 co){
    return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

float PHI = 1.61803398874989484820459;

float gold_noise(vec2 xy)
{
    return fract(tan(distance(xy*PHI, xy)*u_seed)*xy.x);
}

vec4 permute(vec4 t) {
    return (t) * ((t ) * 34.0 + 133.0);
}

// Gradient set is a normalized expanded rhombic dodecahedron
vec3 grad(float hash) {
    hash += u_seed;
    // Random vertex of a cube, +/- 1 each
    vec3 cube = mod(floor(hash / vec3(1.0, 2.0, 4.0)), 2.0) * 2.0 - 1.0;
    
    // Random edge of the three edges connected to that vertex
    // Also a cuboctahedral vertex
    // And corresponds to the face of its dual, the rhombic dodecahedron
    vec3 cuboct = cube;
    cuboct[int(hash / 16.0)] = 0.0;
    
    // In a funky way, pick one of the four points on the rhombic face
    float type = mod(floor(hash / 8.0), 2.0);
    vec3 rhomb = (1.0 - type) * cube + type * (cuboct + cross(cube, cuboct));
    
    // Expand it so that the new edges are the same length
    // as the existing ones
    vec3 grad = cuboct * 1.22474487139 + rhomb;
    
    // To make all gradients the same length, we only need to shorten the
    // second type of vector. We also put in the whole noise scale constant.
    // The compiler should reduce it into the existing floats. I think.
    grad *= (1.0 - 0.042942436724648037 * type) * 3.5946317686139184;
    
    return grad;
}

// BCC lattice split up into 2 cube lattices
vec4 openSimplex2SDerivativesPart(vec3 X) {
    vec3 b = floor(X);
    vec4 i4 = vec4(X - b, 2.5);
    
    // Pick between each pair of oppposite corners in the cube.
    vec3 v1 = b + floor(dot(i4, vec4(.25)));
    vec3 v2 = b + vec3(1, 0, 0) + vec3(-1, 1, 1) * floor(dot(i4, vec4(-.25, .25, .25, .35)));
    vec3 v3 = b + vec3(0, 1, 0) + vec3(1, -1, 1) * floor(dot(i4, vec4(.25, -.25, .25, .35)));
    vec3 v4 = b + vec3(0, 0, 1) + vec3(1, 1, -1) * floor(dot(i4, vec4(.25, .25, -.25, .35)));
    
    // Gradient hashes for the four vertices in this half-lattice.
    vec4 hashes = permute(mod(vec4(v1.x, v2.x, v3.x, v4.x), 289.0));
    hashes = permute(mod(hashes + vec4(v1.y, v2.y, v3.y, v4.y), 289.0));
    hashes = mod(permute(mod(hashes + vec4(v1.z, v2.z, v3.z, v4.z), 289.0)), 48.0);
    
    // Gradient extrapolations & kernel function
    vec3 d1 = X - v1; vec3 d2 = X - v2; vec3 d3 = X - v3; vec3 d4 = X - v4;
    vec4 a = max(0.75 - vec4(dot(d1, d1), dot(d2, d2), dot(d3, d3), dot(d4, d4)), 0.0);
    vec4 aa = a * a; vec4 aaaa = aa * aa;
    vec3 g1 = grad(hashes.x); vec3 g2 = grad(hashes.y);
    vec3 g3 = grad(hashes.z); vec3 g4 = grad(hashes.w);
    vec4 extrapolations = vec4(dot(d1, g1), dot(d2, g2), dot(d3, g3), dot(d4, g4));
    
    // Derivatives of the noise
    vec3 derivative = -8.0 * mat4x3(d1, d2, d3, d4) * (aa * a * extrapolations)
        + mat4x3(g1, g2, g3, g4) * aaaa;
    
    // Return it all as a vec4
    return vec4(derivative, dot(aaaa, extrapolations));
}

// Use this if you don't want Z to look different from X and Y
vec4 openSimplex2SDerivatives_Conventional(vec3 X) {
    X = dot(X, vec3(2.0/3.0)) - X;
    
    vec4 result = openSimplex2SDerivativesPart(X) + openSimplex2SDerivativesPart(X + 144.5);
    
    return vec4(dot(result.xyz, vec3(2.0/3.0)) - result.xyz, result.w);
}

// Use this if you want to show X and Y in a plane, then use Z for time, vertical, etc.
vec4 openSimplex2SDerivatives_ImproveXY(vec3 X) {
    
    // Not a skew transform.
    mat3 orthonormalMap = mat3(
        0.788675134594813, -0.211324865405187, -0.577350269189626,
        -0.211324865405187, 0.788675134594813, -0.577350269189626,
        0.577350269189626, 0.577350269189626, 0.577350269189626);
    
    X = orthonormalMap * X;
    vec4 result = openSimplex2SDerivativesPart(X) + openSimplex2SDerivativesPart(X + 144.5);
    
    return vec4(result.xyz * orthonormalMap, result.w);
}

vec3 voronoi(vec2 t)
{
    vec2 baseCell = floor(t);

    float minDistToCell = 10;
    vec2 closestCell;
    vec2 toClosestCell;
    for(int x = -1; x <= 1; x++)
    {
        for(int y = -1; y <= 1; y++)
        {
            vec2 cell = baseCell + vec2(x,y);
            vec2 cellPos = cell + gold_noise(cell );
            vec2 toCell = cellPos - t;
            float dist = length(toCell);
            if(dist < minDistToCell)
            {
                minDistToCell = dist;
                closestCell = cell;
                toClosestCell = toCell;
            }
            
        
        }
    
    }
    float minEdgeDistance = 10;
    for(int x = -1; x <= 1; x++)
    {
        for(int y = -1; y <= 1; y++)
        {
            vec2 cell = baseCell + vec2(x,y);
            vec2 cellPos = cell + gold_noise(cell );
            vec2 toCell = cellPos - t;
            vec2 diffToClosestCell = abs(closestCell - cell);
            bool isClosestCell = diffToClosestCell .x + diffToClosestCell.y < 0.1;
            if(!isClosestCell)
            {
                vec2 toCenter = (toClosestCell + toCell) *0.5;
                vec2 cellDifference = normalize(toCell - toClosestCell);
                float edgeDistance = dot(toCenter, cellDifference);
                minEdgeDistance = min(minEdgeDistance,edgeDistance);
            
            }
        }
    }

    float random = gold_noise(closestCell );
    

    return vec3(minDistToCell,random,minEdgeDistance);

}



void main()
{

    vec3 uv = vec3(gl_GlobalInvocationID.xyz) / vec3(imageSize(img_output),1);
    vec4 simplexVal = vec4(0);
    float amplitude = 1;
    float maxAmp = 0;
    float frequencey = 2;
    for (int i = 0; i <6; i++)
    {
        simplexVal += openSimplex2SDerivatives_Conventional(uv * frequencey) * amplitude;
        
        frequencey *= 2;
        maxAmp += amplitude;
        amplitude *= 0.5;

    }

    simplexVal /= maxAmp;
    amplitude = 1;
    maxAmp = 0;
    frequencey = 2;

    vec3 voronoiVal = vec3(0);
    
    for(int i = 0; i <4; i++)
    {
         voronoiVal += voronoi(uv.xy * frequencey) * amplitude;
         frequencey *= 2;
         maxAmp += amplitude;
         amplitude *= 0.5;
    }
    voronoiVal /= maxAmp;

	vec4 pixel = vec4(vec3(voronoiVal.z + simplexVal.w),1);
	ivec2 coords = ivec2(gl_GlobalInvocationID.xy);
	imageStore(img_output,coords,pixel);


}