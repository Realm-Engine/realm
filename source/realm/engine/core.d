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
	quat quatRotation;
	vec3 scale;

	private Transform parent;
	private Transform[] children;

	private mat4 transformMat;
	
	mixin RealmComponent;

	this(vec3 position, vec3 rotation, vec3 scale)
	{
		this.position = position;
		this.quatRotation = quat.euler_rotation(rotation.z,rotation.x,rotation.y);
		this.scale = scale;
	}
	this()
	{
		this.position = vec3(0,0,0);
		quatRotation = quat(0,0,0,1);
		this.scale = vec3(1,1,1);
		transformMat = mat4(1.0f);
	}


	this(Transform other)
	{
		position = other.position;
		quatRotation = other.quatRotation;
		scale = other.scale;
	}

	@property mat4 transformation()
	{
		return transformMat;
	}
	@property void transformation(mat4 t)
	{
		transformMat = t;
	}

	@property rotation(vec3 euler)
	{

		quatRotation = quat.euler_rotation(radians( euler.z),radians(euler.x),radians(euler.y));
	}
	@property vec3 rotation()
	{
		float yaw = quatRotation.yaw;
		float pitch = quatRotation.pitch;
		float roll = quatRotation.roll;
		return vec3(pitch,yaw,roll);
	}
	

	@property front()
	{

		float yaw = quatRotation.yaw;
		float pitch = quatRotation.pitch;
		float roll = quatRotation.roll;
		vec3 dir = vec3(0);
		dir.x = cos(radians(yaw)) * cos(radians(pitch));
		dir.y = sin(radians(pitch));
		dir.z = sin(radians(yaw)) * cos(radians(pitch));
		dir.normalize();
		return dir;
		
	}
	




	
	void updateTransformation()
	{
		
		vec3 postionRelation = vec3(0);
		vec3 rotationRelation = vec3(0);
		vec3 scaleRelation = vec3(0);

		vec3 worldPosition = getWorldPosition();
		vec3 worldRotation = getWorldRotation();
		vec3 worldScale = getWorldScale();

		if(parent !is null)
		{
			postionRelation = parent.position;
			rotationRelation = parent.rotation;
			scaleRelation = parent.scale;
		}


		mat4 M = mat4.identity;
		
		M = M.scale(worldScale.x ,worldScale.y ,worldScale.z);
		
		mat4 rotationMat = quatRotation.normalized().to_matrix!(4,4)();
		//M.rotate(worldRotation.x ,vec3(1,0,0));
		//M.rotate(worldRotation.y ,vec3(0,1,0));
		//M.rotate(worldRotation.z ,vec3(0,0,1));
		M *= rotationMat;
		M = M.translate(worldPosition.x ,worldPosition.y ,worldPosition.z );

		transformMat = M;
	}

	void lookAt(vec3 x, vec3 y, vec3 z)
	{
		transformMat *= mat4.look_at(x,y,z);
	}

	void componentUpdate(E)(E parent)
	{
		updateTransformation();

	}

	void setParent(Transform parent)
	{
		this.parent = parent;
		parent.addChild(this);


	}
	private void addChild(Transform child)
	{
		children ~= child;
	}

	vec3 getWorldPosition()
	{
		if(parent is null)
		{
			return position;
		}
		return position + parent.getWorldPosition();
	}

	vec3 getWorldRotation()
	{
		if(parent is null)
		{
			return rotation;
		}
		return rotation + parent.getWorldRotation();
	}
	vec3 getWorldScale()
	{
		if(parent is null)
		{
			return scale;
		}
		return scale + parent.getWorldScale();
	}
}


struct Mesh
{

	mixin RealmComponent;

	vec3[] positions;
	vec2[] textureCoordinates;
	vec3[] normals;
	vec3[] tangents;
	uint[] faces;
	private AABB localBounds;
	private AABB worldBounds;
	

	void componentStart(E)(E parent)
	{
		worldBounds = localBounds = AABB.from_points(positions);
	}


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

	

	private void calculateWorldBoundingBox(Transform transform)
	{
		mat4 modelMatrix = transform.transformation;
		auto xa = vec4(modelMatrix[0]) * localBounds.min.x;
		auto xb = vec4(modelMatrix[0]) * localBounds.max.x;

		auto ya = vec4(modelMatrix[1]) * localBounds.min.y;
		auto yb = vec4(modelMatrix[1]) * localBounds.max.y;
		auto za = vec4(modelMatrix[2]) * localBounds.min.z;
		auto zb = vec4(modelMatrix[2]) * localBounds.max.z;

		vec3 test = min(xa, xb);

	}

	void componentUpdate(E)(E parent)
	{
		static if(hasComponent!(E, Transform))
		{
			calculateWorldBoundingBox(parent.getComponent!(Transform));
		}
	}

	AABB getLocalBounds()
	{
		return localBounds;
	}
	AABB getWorldBounds()
	{
		return worldBounds;
	}


	
}

enum CameraProjection
{
	PERSPECTIVE,
	ORTHOGRAPHIC
}


enum ProjectionWindowBounds
{
	ZERO_TO_ONE,
	NEGATIVE_HALF_TO_HALF,
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
	ProjectionWindowBounds projBounds = ProjectionWindowBounds.NEGATIVE_HALF_TO_HALF;
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
				if(projBounds == ProjectionWindowBounds.NEGATIVE_HALF_TO_HALF)
				{
					proj = mat4.orthographic(-size.x/2,size.x/2,-size.y/2,size.y,nearPlane,farPlane);
				}
				else
				{
					proj = mat4.orthographic(0,size.x,0,size.y,nearPlane,farPlane);
				}
				
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
		shadowFrameBuffer.fbAttachments[FrameBufferAttachmentType.DEPTH_ATTACHMENT].texture.wrap = TextureWrapFunc.CLAMP_TO_BORDER;
		shadowFrameBuffer.fbAttachments[FrameBufferAttachmentType.DEPTH_ATTACHMENT].texture.border = [1.0,1.0,1.0,1.0];
	}

}


