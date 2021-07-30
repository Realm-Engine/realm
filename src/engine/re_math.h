#pragma once
#include <math.h>



typedef struct {
	union {
		struct
		{
			float x;
			float y;

		};
		float ptr_raw[2];
	};
} vec2_t;
typedef struct {
	union {
		struct 
		{
			float x;
			float y;
			float z;
		};
		float ptr_raw[3];
	};
} vec3_t;
typedef struct {
	union {
		struct
		{
			float x;
			float y;
			float z;
			float w;
		};
		float ptr_raw[4];
	};
} vec4_t;



typedef struct {
	union {
		struct {
			vec4_t x;
			vec4_t y;
			vec4_t z;
			vec4_t w;
		};
		vec4_t ptr_raw[4];
	};
}mat4x4_t;

#define vec3(x,y,z)		(vec3_t){x,y,z}
#define vec4(x,y,z,w)	(vec4_t){x,y,z,w}
#define mat4x4(x,y,z,w) (mat4x4_t){x,y,z,w}
#define re_cos(x) cosf(x)
#define re_sin(x) sinf(x)
#define re_tan(x) tanf(x)


static inline float vec3_len(vec3_t v) {
	float val = v.x * v.x + v.y * v.y + v.z * v.z;
	return sqrt(val);
}
static inline float vec3_dot(vec3_t a, vec3_t b)
{
	return a.x * b.x + a.y * b.y + a.z * b.z;
}
static inline vec3_t vec3_add(vec3_t a, vec3_t b)
{
	vec3_t r;
	r.x = a.x + b.x;
	r.y = a.y + b.y;
	r.z = a.z + b.z;
	return r;
}
static inline vec3_t vec3_cross_mul(vec3_t a, vec3_t b)
{
	vec3_t r;
	r.x = a.y * b.z - a.z * b.y;
	r.y = a.z * b.x - a.x * b.z;
	r.z = a.x * b.y - a.y * b.x;
	return r;

}
static inline vec3_t vec3_scalar_mul(vec3_t a, float scalar)
{

	vec3_t r;
	r.x = a.x * scalar;
	r.y = a.y * scalar;
	r.z = a.z * scalar;
	return r;

}
static inline vec4_t vec4_add(vec4_t a, vec4_t b)
{
	vec4_t r;
	r.x = a.x + b.x;
	r.y = a.y + b.y;
	r.z = a.z + b.z;
	r.w = a.w + b.w;
	return r;
}
static inline float vec4_len(vec4_t v) {
	float val = v.x * v.x + v.y * v.y + v.z * v.z + v.w * v.w;
	return sqrt(val);
}


static inline float vec4_dot(vec4_t a, vec4_t b)
{
	return a.x * b.x + a.y * b.y + a.z * b.z + a.w * b.w;
}


static inline vec4_t vec4_cross_mul(vec4_t a, vec4_t b)
{
	vec4_t r;
	
	r.x = a.y * b.z - a.z * b.y;
	r.y = a.z * b.x - a.x * b.z;
	r.z = a.x * b.y - a.y * b.x;
	r.w = 1.0f;
}

static inline vec4_t vec4_scalar_mul(vec4_t a, float scalar)
{

	vec4_t r;
	
	r.x = a.x * scalar;
	r.y = a.y * scalar;
	r.z = a.z * scalar;
	r.w = a.w * scalar;
	return r;
}

static inline mat4x4_t mat4x4_mul(mat4x4_t a, mat4x4_t b)
{
	mat4x4_t r;

	for (int i = 0; i < 4; i++)
	{
		for (int j = 0; j < 4; j++)
		{
			r.ptr_raw[i].ptr_raw[j] = 
				a.ptr_raw[i].x * b.x.ptr_raw[j] +
				a.ptr_raw[i].y * b.y.ptr_raw[j] +
				a.ptr_raw[i].z * b.z.ptr_raw[j] +
				a.ptr_raw[i].w * b.w.ptr_raw[j];

		}
	}


}

static inline mat4x4_t re_perspective(float fov, float aspectRatio, float near, float far)
{
	
	float scale = 1.0f / tanf(fov / 2.0f);
	mat4x4_t r;
	memset(&r, 0, sizeof(mat4x4_t));
	r.x.x = scale;
	r.y.y = scale;
	r.z.z = -far / (far - near);
	r.w.z = -far * near / (far - near);
	r.z.w = -1;
	r.w.w = 0;
	return r;

}

static inline mat4x4_t re_orthographic(float right, float left, float top, float bottom,float near,float far)
{
	mat4x4_t orthoMat;
	memset(&orthoMat, 0, sizeof(mat4x4_t));
	orthoMat.x.x = 2.0f / (right - left);
	
	orthoMat.y.y = 2/(top-bottom);
	orthoMat.z.z = -2/(far-near);
	orthoMat.w.x = -(right + left) / (right - left);
	orthoMat.w.y = -(top + bottom) / (top - bottom);
	orthoMat.w.z = -(far + near) / (far - near);
	orthoMat.w.w = 1.0f;
	return orthoMat;

}

static inline mat4x4_t re_matrix4x4_identity()
{
	mat4x4_t mat;
	mat.x = vec4(1, 0, 0, 0);
	mat.y = vec4(0, 1, 0, 0);
	mat.z = vec4(0, 0, 1, 0);
	mat.w = vec4(0, 0, 0, 1);

}

static inline mat4x4_t re_rotate_x(float angle)
{
	mat4x4_t mat = re_matrix4x4_identity();

	memset(&mat, 0, sizeof(mat4x4_t));
	float c = re_cos(angle);
	float s = re_sin(angle);
	mat.x.x = 1.0f;
	mat.y.y = c;
	mat.y.z = -s;
	mat.z.y = s;
	mat.z.z = c;
	return mat;


}
static inline mat4x4_t re_rotate_x(float angle)
{
	mat4x4_t mat = re_matrix4x4_identity();

	memset(&mat, 0, sizeof(mat4x4_t));
	float c = re_cos(angle);
	float s = re_sin(angle);
	
	return mat;


}


