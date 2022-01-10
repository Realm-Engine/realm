module realm.engine.core;
import realm.engine.graphics.core;
import std.stdio;
import realm.engine.app;
public
{
	import gl3n.aabb;
	import gl3n.linalg;
	import gl3n.math;
	import std.file : read;
	import realm.engine.logging;
	import realm.engine.ecs;
	import realm.engine.asset;
	import std.meta;
	import std.typecons;
	import realm.engine.input;
}

class Transform
{
	import std.meta;
	vec3 position;
	vec3 rotation;
	vec3 scale;
	private mat4 transformMat;
	this(vec3 position, vec3 rotation, vec3 scale)
	{
		this.position = position;
		this.rotation = rotation;
		this.scale = scale;
	}
	this()
	{
		this.position = vec3(0,0,0);
		this.rotation = vec3(0,0,0);
		this.scale = vec3(1,1,1);
		transformMat = mat4(1.0f);
	}
	@property mat4 transformation()
	{
		return transformMat;
	}

	@property front()
	{
		vec3 dir = vec3(0);
		dir.x = cos(radians(rotation.y)) * cos(radians(rotation.x));
		dir.y = sin(radians(rotation.x));
		dir.z = sin(radians(rotation.y)) * cos(radians(rotation.x));
		dir.normalize();
		return dir;
		
	}
	
	/*vec3 computeDirection(vec3 direction)
	{
		vec4 dir = rotation.to_matrix!(4,4) * vec4(direction,1.0);
		
		return vec3(dir).normalized();

	}
	

	@property up()
	{
		return computeDirection(vec3(0,1,0));
	}
	@property right()
	{
		return computeDirection(vec3(1,0,0));
	}*/


	
	void updateTransformation()
	{

		mat4 M = mat4.identity;
		
		M = M.scale(scale.x,scale.y,scale.z);
		M.rotate(rotation.x,vec3(1,0,0));
		M.rotate(rotation.y,vec3(0,1,0));
		M.rotate(rotation.z,vec3(0,0,1));
		M = M.translate(position.x,position.y,position.z).matrix;


		transformMat = M;
	}

	void lookAt(vec3 x, vec3 y, vec3 z)
	{
		transformMat *= mat4.look_at(x,y,z);
	}

	void componentUpdate()
	{
		updateTransformation();

	}
}


struct BoundingBox
{
	private AABB boundingBox;
	private Transform* transform;
	void initialize(vec3[] vertices, Transform* transform)
	{
		this.transform = transform;
		boundingBox = AABB.from_points(vertices);
	}
	const vec3 extents(bool scaled = true)()
	{
		Logger.Assert(boundingBox.vertices.length > 0, "Bounding box not constructed");
		if(scaled)
		{
			Logger.Assert(transform !is null,"Transform for bounding box not set");
			vec3 extents = boundingBox.extent();
			return vec3(extents.x*transform.scale.x,extents.y*transform.scale.y,extents.z*transform.scale.z);
		}
		else
		{
			return boundingBox.extent();
		}
	}
	const vec3 center(bool translated = true)()
	{
		Logger.Assert(boundingBox.vertices.length > 0, "Bounding box not constructed");
		static if(translated)
		{
			Logger.Assert(transform !is null,"Transform for bounding box not set");
			return boundingBox.center + transform.position;
		}
		static if(!translated)
		{
			
			return boundingBox.center;
		}
	}




}

struct Mesh
{
	vec3[] positions;
	vec2[] textureCoordinates;
	vec3[] normals;
	vec3[] tangents;
	uint[] faces;

	void calculateNormals()
	{
		normals.length = positions.length;
		
		for(int i = 0; i < faces.length;i+=3)
		{
			uint[3] triangleFace = faces[i..(i+3)];
			vec3[3] triangle;
			triangle[0] = positions[triangleFace[0]];
			triangle[1] = positions[triangleFace[1]];
			triangle[2] = positions[triangleFace[2]];

			vec3 ab = triangle[1] - triangle[0];
			vec3 ac = triangle[2] - triangle[0];
			vec3 normal = cross(ab,ac);
			normals[triangleFace[0]] = normal;
			normals[triangleFace[1]] = normal;
			normals[triangleFace[2]] = normal;
		}
	}

	

	void calculateTangents()
	{
		assert(normals.length >0);
		tangents.length = normals.length;
		for(int i = 0; i < faces.length;i+=3)
		{
			uint[3] triangleFace = faces[i..(i+3)];
			vec3[3] triPositions;
			triPositions[0] = positions[triangleFace[0]];
			triPositions[1] = positions[triangleFace[1]];
			triPositions[2] = positions[triangleFace[2]];
			vec2[3] triCoordinates;
			triCoordinates[0] = textureCoordinates[triangleFace[0]];
			triCoordinates[1] = textureCoordinates[triangleFace[1]];
			triCoordinates[2] = textureCoordinates[triangleFace[2]];
			vec3 edge1 = triPositions[1] - triPositions[0];
			vec3 edge2 = triPositions[2] - triPositions[0];
			vec2 deltaUV1 = triCoordinates[1] - triCoordinates[0];
			vec2 deltaUV2 = triCoordinates[2] - triCoordinates[0];
			float c = 1.0f / (deltaUV1.x * deltaUV2.y - deltaUV2.x * deltaUV1.y);
			vec3 tangent;
			tangent.x = c *(deltaUV2.y * edge1.x - deltaUV1.y * edge2.x);
			tangent.y = c * (deltaUV1.y * edge1.y - deltaUV1.y * edge2.y);
			tangent.z = c *(deltaUV2.y * edge1.z - deltaUV1.y * edge2.z);
			tangents[triangleFace[0]] = tangent;
			tangents[triangleFace[1]] = tangent;
			tangents[triangleFace[2]] = tangent;

		}
	}


	
}

enum CameraProjection
{
	PERSPECTIVE,
	ORTHOGRAPHIC
}

class Camera
{
	Transform transform;
	float fieldOfView;
	vec2 size;
	float farPlane;
	float nearPlane;
	private CameraProjection projectionType;
	mat4 vp;
	mat4 cameraTransformation;
	float yaw;
	float pitch;
	//Front
	//Maybe goes in transform?
	
	@property projection()
	{
		return calculateProjection();
	}
	@property view()
	{
		return cameraTransformation;
	}
	@property view(mat4 view)
	{
		cameraTransformation = view;
	}
	@property front()
	{
		vec3 dir = vec3(0);
		dir.x = cos(radians(yaw)) * cos(radians(pitch));
		dir.y = sin(radians(pitch));
		dir.z = sin(radians(yaw)) * cos(radians(pitch));
		dir.normalize();
		return dir;
	}




	alias transform this;

	this(CameraProjection projectionType, vec2 size,float nearPlane,float farPlane,float fieldOfView)
	{
		this.projectionType = projectionType;
		this.size = size;
		this.farPlane = farPlane;
		this.nearPlane = nearPlane;
		this.fieldOfView = fieldOfView;
		yaw = 0;
		pitch = 0;
		transform = new Transform;
		update();
	}

	private mat4 calculateProjection()
	{
		mat4 proj;
		switch(projectionType)
		{
			case CameraProjection.PERSPECTIVE:
				proj = mat4.perspective(size.x,size.y,fieldOfView,nearPlane,farPlane);
				break;
			case CameraProjection.ORTHOGRAPHIC:
				proj = mat4.orthographic(-size.x,size.x,-size.y,size.y,nearPlane,farPlane);
				break;
			default:
				proj = mat4.perspective(size.x,size.y,fieldOfView,nearPlane,farPlane);
				break;
		}
		//proj.transpose();
		return proj;


	}

	void turn(vec2 v)
	{
		yaw += v.x;
		pitch += v.y;
	}
	
	void updateViewProjection(mat4 view)
	{
		mat4 proj = calculateProjection();
		vp = proj * view;
	}

	void update()
	{
		mat4 lookMat = mat4(mat4.look_at(transform.position,transform.position + front, vec3(0,1,0)));
		lookMat.matrix[3] = vec4(0,0,0,1).vector;
		mat4 translation = mat4.identity;
		translation.matrix[3] = vec4(-transform.position.x,-transform.position.y,-transform.position.z,1.0).vector;
		cameraTransformation = lookMat;
	}
	void cameraLookAt(float x,float y, float z)
	{
		mat4 lookMat = mat4(mat4.look_at( transform.position,transform.position + vec3(x,y,z),vec3(0,1,0)));
		lookMat.matrix[3] = vec4(0,0,0,1).vector;
		mat4 translation = mat4.identity;
		translation.matrix[3] = vec4(-transform.position.x,-transform.position.y,-transform.position.z,1.0).vector;
		cameraTransformation = lookMat;
	}

	


}

struct DirectionalLight
{
	Transform transform;
	vec3 color; 
	FrameBuffer shadowFrameBuffer; 
	void createFrameBuffer(int width, int height)
	{

		shadowFrameBuffer.create!([FrameBufferAttachmentType.DEPTH_ATTACHMENT])(width,height);

	}

}