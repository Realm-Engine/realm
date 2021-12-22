module realm.engine.core;
public import gl3n.linalg;
import gl3n.math;
import realm.engine.logging;
import std.stdio;
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

	
	
	/*vec3 computeDirection(vec3 direction)
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
	}*/


	
	void updateTransformation()
	{

		mat4 M = mat4.identity;
		
		M = M.scale(scale.x,scale.y,scale.z);
		M = M.translate(position.x,position.y,position.z).matrix;
		M.rotate(rotation.x,vec3(1,0,0));
		M.rotate(rotation.y,vec3(0,1,0));
		M.rotate(rotation.z,vec3(0,0,1));

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

struct Mesh
{
	vec3[] positions;
	vec2[] textureCoordinates;
	vec3[] normals;
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
	private CameraProjection projectionType;
	private mat4 vp;
	private mat4 cameraTransformation;
	private float yaw;
	private float pitch;
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

	


}