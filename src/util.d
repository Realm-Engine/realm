module realm.util;
import realm.engine.core;
import gl3n.linalg;
import std.range;
import gl3n.math : atan2,asin;
Mesh generateSphere(int res)
{
	vec3[] faceNormals = [vec3(0,1,0),vec3(0,-1,0),vec3(-1,0,0),vec3(1,0,0),vec3(0,0,1),vec3(0,0,-1)];
	Mesh cube;
	foreach(i,normal;enumerate(faceNormals,0))
	{
		Mesh face = generateFace(normal,res);

		cube.positions ~= face.positions;
		cube.normals ~= face.normals;
		cube.textureCoordinates ~= face.textureCoordinates;

		foreach(idx; face.faces)
		{
			cube.faces ~= idx  + ((res*res) * i) ;
		}
	}

	vec2 pointToCoord(vec3 point)
	{
		float latitude = asin(point.y);
		float longitude = atan2(point.x, - point.z);
		return vec2(latitude,longitude);
	}

	foreach(i,pos;cube.positions)
	{
		(&cube.positions[i]).normalize();

	}
	return cube;
	//meshData.calculateNormals();

}



Mesh generateFace(vec3 normal, int resolution)
{
	vec3 axisA = vec3(normal.y,normal.z,normal.x);
	vec3 axisB = normal.cross(axisA);
	vec3[] vertices = new vec3[](resolution * resolution);
	uint[] faces = new uint[]((resolution - 1) * (resolution - 1)  * 6);
	vec2[] uv = new vec2[](resolution * resolution);
	int triIndex = 0;
	for(int y = 0; y < resolution;y++)
	{
		for(int x = 0; x < resolution; x++)
		{
			int vertexIndex = x + y * resolution;
			vec2 t = vec2(x,y) / (resolution - 1.0f);
			vec3 point = normal + axisA * (2 * t.x -1) + axisB * (2 * t.y - 1);
			vertices[vertexIndex] = point;
			uv[vertexIndex] = t;
			if(x != resolution -1 && y != resolution - 1)
			{
				faces[triIndex + 0] = vertexIndex;
				faces[triIndex + 1] = vertexIndex + resolution + 1;
				faces[triIndex + 2] = vertexIndex + resolution;
				faces[triIndex + 3] = vertexIndex;
				faces[triIndex + 4] = vertexIndex + 1;
				faces[triIndex + 5] = vertexIndex + resolution + 1;
				triIndex +=6;
			}
		}
	}
	Mesh mesh;
	mesh.positions = vertices;
	mesh.textureCoordinates = uv;
	mesh.faces = faces;
	mesh.normals = new vec3[](mesh.positions.length);
	mesh.normals[0..$] = normal;
	mesh.calculateTangents();
	return mesh;

}