module realm.engine.core;
import gl3n.linalg;

class Transform
{
	import std.meta;
	vec3 position;
	quat rotation;
	vec3 scale;
	this(vec3 position, quat rotation, vec3 scale)
	{
		this.position = position;
		this.rotation = rotation;
		this.scale = scale;
	}
	this()
	{
		this.position = vec3(0,0,0);
		this.rotation = quat(0,0,0,0);
		this.scale = vec3(1,1,1);
	}
	@property mat4 model()
	{
		mat4 M = mat4.identity;
		M = M.scale(scale.x,scale.y,scale.z);
		quat normalizedRot = rotation.normalized();
		mat4 rotationMatrix = normalizedRot.to_matrix!(4,4);
		M = M * rotationMatrix;
		M = M.translate(position.x,position.y,position.z).matrix;
		return M;
		
	}
	
	vec3 computeDirection(vec3 direction)
	{
		vec4 dir = rotation.to_matrix!(4,4) * vec4(direction,1.0);
		
		return vec3(dir).normalized();

	}
	
	@property front()
	{
		return computeDirection(vec3(0,0,1));
	}
	@property up()
	{
		return computeDirection(vec3(0,1,0));
	}
	@property right()
	{
		return computeDirection(vec3(1,0,0));
	}


	mat4 lookAt(vec3 eye, vec3 target, vec3 up)
	{
		return mat4.look_at(eye,target,up);
	}
	

	@property eulerRotation(vec3 euler) 
	{
		rotation = quat.euler_rotation(euler.x,euler.y,euler.z);
	}
	void rotateEuler(vec3 axis)
	{
		rotation = rotation.rotate_euler(axis.x,axis.y,axis.z);
	}
	
}

class Mesh
{
	vec3[] positions;
	vec2[] textureCoordinates;
	vec3[] normals;
	uint[] faces;
	this(){}
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

	
}

enum CameraProjection
{
	PERSPECTIVE,
	ORTHOGRAPHIC
}

class Camera
{
	Transform transform;
	private float fieldOfView;
	private vec2 size;
	private float farPlane;
	private float nearPlane;
	private CameraProjection projection;
	private mat4 vp;
	//Front
	//Maybe goes in transform?
	
	@property viewProjection()
	{
		return vp;
	}
	alias transform this;

	this(CameraProjection projectionType, vec2 size,float farPlane,float nearPlane,float fieldOfView)
	{
		this.projection = projectionType;
		this.size = size;
		this.farPlane = farPlane;
		this.nearPlane = nearPlane;
		this.fieldOfView = fieldOfView;
		transform = new Transform;
		updateViewProjection();
	}

	private mat4 calculateProjection()
	{
		mat4 proj;
		switch(projection)
		{
			case CameraProjection.PERSPECTIVE:
				proj = mat4.perspective(size.x,size.y,fieldOfView,nearPlane,farPlane);
				break;
			default:
				proj = mat4.perspective(size.x,size.y,fieldOfView,nearPlane,farPlane);
				break;
		}
		return proj;


	}

	void updateViewProjection()
	{
		mat4 proj = calculateProjection();
		mat4 view = transform.lookAt(transform.position,transform.position + transform.front,transform.up);
		
		vp = proj * view;
	}
	


}