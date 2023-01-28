module realm.engine.core;
private
{
	import realm.engine.graphics.core;
	import std.stdio;
}

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
	quat rotation;
	vec3 scale;
	private mat4 parentTransformation;
	private Transform parent;
	private Transform[] children;

	private mat4 transformMat;
	
	mixin RealmComponent;


	this(vec3 position, vec3 rotation, vec3 scale)
	{
		this.position = position;
		this.rotation = quat.euler_rotation(rotation.z,rotation.x,rotation.y);
		this.scale = scale;
	}
	this()
	{
		this.position = vec3(0,0,0);
		rotation = quat.euler_rotation(0,0,0);
		this.scale = vec3(1,1,1);
		transformMat = mat4.identity;
	}


	this(Transform other)
	{
		position = other.position;
		rotation = other.rotation;
		scale = other.scale;
	}

	@property mat4 transformation()
	{
		return transformMat;
	}

	vec3 scaleFromMatrix(mat4 t)
	{
		mat3 matrix = mat3(t).transposed;
		
		float sx = matrix[0].length;
		float sy = matrix[1].length;
		float sz = matrix[2].length;
		return vec3(sx,sy,sz);
	}
	@property void transformation(mat4 t)
	{

		position = vec3(t[0][3],t[1][3],t[2][3]);
		rotation = quat.from_matrix(mat3(t.get_rotation()));

		transformMat = t;
	}



	void setRotationEuler(vec3 euler)
	{
		rotation = quat.euler_rotation(radians( euler.x),radians(euler.y),radians(euler.z));
	}

	void rotateEuler(vec3 euler)
	{
		rotation = rotation.rotate_euler(radians(euler.x),radians(euler.y),radians(euler.z));
	}

	vec3 getRotationEuler()
	{
		float yaw = rotation.yaw;
		float pitch = rotation.pitch;
		float roll = rotation.roll;
		return vec3(pitch,yaw,roll);
	}

	vec3 front()
	{
		return getWorldRotation() * vec3(0,0,1);
		//float yaw =  rotation.yaw;
		//float pitch = rotation.pitch;
		//float roll = rotation.roll;
		//vec3 dir = vec3(0);
		//dir.x = cos(yaw) * cos(pitch);
		//dir.y = sin(pitch);
		//dir.z = sin(yaw) * cos(pitch);
		//dir.normalize();
		//return dir;
	}
	
	void updateTransformation()
	{
		
		
		mat4 M = mat4.identity;
		M = M.scale(scale.x ,scale.y ,scale.z);
		

		mat4 rotationMat = rotation.normalized().to_matrix!(4,4)();
		M *= rotationMat;
		M = M.translate(position.x ,position.y ,position.z );
		
		
		mat4 parentTransform = mat4.identity;
		Transform currentParent = parent;
		while(currentParent !is null)
		{
			M = currentParent.transformation * M;
			currentParent = currentParent.getParent();
		}
		
		

		transformMat = M;
		
		
	}

	private mat4 resolveHierarchy()
	{
		if(parent !is null)
		{
			return  parent.resolveHierarchy() * transformMat;
		}
		
		return transformMat;
		



	}

	void lookAt(vec3 x, vec3 y, vec3 z)
	{
		transformMat *= mat4.look_at(x,y,z);
	}

	

	void componentUpdate()
	{
		updateTransformation();
		

	}

	void setParent(Transform parent)
	{
		this.parent = parent;
		parent.addChild(this);


	}

	Transform getParent()
	{
		return parent;
	}

	void addChild(Transform child)
	{
		children ~= child;
	}

	Transform[] getChildren()
	{
		return children;
	}

	int opApply(int delegate(Transform)dg)
	{
		int result = 0;
		
		foreach(child; children)
		{
			result = dg(child);
			if(result)
			{
				break;
			}
		}
		return result;
	}

	private mat4 worldTransform()
	{
		if(parent !is null)
		{
			return parent.worldTransform() * transformMat;
		}
		return transformMat;
	}

	vec3 getWorldPosition()
	{
		
		return vec3(transformMat[0][3],transformMat[1][3],transformMat[2][3]);
	}

	quat getWorldRotation()
	{
		
		return quat.from_matrix(mat3(transformMat.get_rotation()));
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

	

	vec3[] positions;
	vec2[] textureCoordinates;
	vec3[] normals;
	vec3[] tangents;
	uint[] faces;
	private AABB localBounds;
	private AABB worldBounds;
	bool isStatic;

	void componentStart()
	{
		calculateWorldBoundingBox();
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
			float delta = (deltaUV1.x * deltaUV2.y - deltaUV2.x * deltaUV1.y);
			if(delta == 0)
			{
				tangents[triangleFace[0]] = vec3(1.0f);
				tangents[triangleFace[1]] = vec3(1.0f);
				tangents[triangleFace[2]] = vec3(1.0f);
			}
			else
			{
				float c = 1.0f / delta;
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

	

	void calculateWorldBoundingBox()
	{
		worldBounds = localBounds = AABB.from_points(positions);

	}

	void componentUpdate(E)(E parent)
	{
		

	}

	AABB getLocalBounds()
	{
		return localBounds;
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
	mixin RealmComponent;
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






	alias transform this;

	void componentStart(CameraProjection projectionType, vec2 size,float nearPlane,float farPlane,float fieldOfView)
	{
		this.projectionType = projectionType;
		this.size = size;
		this.farPlane = farPlane;
		this.nearPlane = nearPlane;
		this.fieldOfView = fieldOfView;
		transform = new Transform;
		componentUpdate();
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
		if(degrees(transform.rotation.pitch) > 89.0f || degrees(transform.rotation.pitch) < -89.0f)
		{
			v.x = 0;
		}

		transform.rotation.rotate_euler(radians(v.y),radians(v.x),0);
		
	}
	
	void updateViewProjection(mat4 view)
	{
		mat4 proj = calculateProjection();
		vp = proj * view;
	}

	void componentUpdate()
	{
		transform.updateTransformation();
		vec3 position = transform.getWorldPosition();
		mat4 lookMat = mat4(mat4.look_at(position,position + transform.front, vec3(0,1,0)));
		lookMat.matrix[3] = vec4(0,0,0,1).vector;
		mat4 translation = mat4.identity;
		translation.matrix[3] = vec4(-position.x,-position.y,-position.z,1.0).vector;
		cameraTransformation = lookMat;
		
	}

}

AABB aabbTransformWorldSpace(AABB box, mat4 matrix)
{
	vec3 aMin = box.min;
	vec3 aMax = box.max;
	vec3 translation = vec3(matrix[0][3],matrix[1][3],matrix[2][3]);
	vec3 bMin,bMax;
	bMax = bMin =  translation;
	mat3 transform = mat3(matrix);
	for(int i = 0; i < 3; i++)
	{
		for(int j = 0; j < 3; j++)
		{
			float a = transform[i][j] * aMin.value_ptr[j];
			float b = transform[i][j] * aMax.value_ptr[j];
			if(a < b)
			{
				bMin.vector[i] += a;
				bMax.vector[i] += b;
			}
			else
			{
				bMin.vector[i] += b;
				bMax.vector[i] += a;
			}
		}
	}
	AABB result = AABB(bMin,bMax);
	return result;
}

class DirectionalLight
{
	//mixin RealmEntity!("Directional Light",Transform);
	//Transform transform;
	vec3 color; 
	
	void start()
	{

	}

	void draw()
	{
		
		

	}

	void update(float dt)
	{
		
		//updateComponents();
		draw();
	}

}

class MeshRenderer
{
	import realm.engine.graphics.material : MaterialData;
	Mesh mesh;
	MaterialData material;
	mixin RealmComponent;
	
	void componentStart(Mesh mesh, MaterialData material)
	{
		this.mesh = mesh;
		this.material = material;
	}

}



template IsInterface(T,Members...)
{
	static foreach(member; Members)
	{
		static if(!__traits(hasMember,T,member))
		{
			static assert(false,T.stringof ~ " does not have member " ~ member ~ ". It must implement the member");
		}
	}

}

