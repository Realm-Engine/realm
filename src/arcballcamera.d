module realm.arcballcamera;
import realm.engine.core;
import gl3n.linalg;
import gl3n.math;
import std.stdio;

class ArcballCamera
{

	private mat4 centerTranslation;
	private mat4 translation;
	private quat rotation;
	mat4 camera;
	private mat4 invCamera;
	
	this(vec3 eye, vec3 center, vec3 up)
	{
		vec3 dir = center - eye;
		vec3 zAxis = dir.normalized();
		vec3 xAxis = zAxis.cross(up);
		xAxis.normalize();
		vec3 yAxis = xAxis.cross(zAxis);
		yAxis.normalize();
		xAxis = zAxis.cross(yAxis);
		xAxis.normalize();
		centerTranslation = mat4.translation(center).inverse();
		translation = mat4.translation(0,0,-dir.length);
		mat3 transposed = mat3(xAxis,yAxis,-zAxis);
		transposed.transpose();
		rotation = quat.from_matrix( transposed).normalized();
		updateCamera();
	}
	@property eye()
	{
		return vec3(invCamera * vec4(0,0,0,1));
	}
	@property dir()
	{
		return vec3(invCamera * vec4(0,0,-1,0)).normalized();
	}
	@property up()
	{
		return vec3(invCamera * vec4(0,1,0,0)).normalized();
	}
	void updateCamera()
	{
		camera = translation * rotation.to_matrix!(4,4)() * centerTranslation;
		invCamera = camera.inverse();
	}
	void componentUpdate()
	{
		//updateCamera();
	}
	void rotate(vec2 prevMouse,vec2 currMouse)
	{
		currMouse.x = clamp(currMouse.x,-1,1);
		currMouse.y = clamp(currMouse.y,-1,1);
		prevMouse.x = clamp(prevMouse.x,-1,1);
		prevMouse.y = clamp(prevMouse.y,-1,1);
	
		quat mouseCurrball = screenToArcball(currMouse);
		quat mousePrevBall = screenToArcball(prevMouse);
		

		rotation = mouseCurrball * mousePrevBall * rotation;
		//writeln(rotation);
		updateCamera();
	}
	void pan(vec2 mouseDelta)
	{
		float zoomAmount = abs(translation.matrix[2][3]);
		vec4 motion = vec4(mouseDelta.x * zoomAmount, mouseDelta.y * zoomAmount,0,0);
		motion = invCamera * motion;
		centerTranslation = mat4.translation(vec3(motion)) * centerTranslation;
		updateCamera();
	}

	quat screenToArcball(vec2 p)
	{
		float dist = p * p;
		if(dist <= 1.0f)
		{
			return quat(0,p.x,p.y,sqrt(1.0f - dist));
		}
		else
		{
			vec2 proj = p.normalized();
			return quat(0.0,proj.x,proj.y,0.0f);
		}
	}




}