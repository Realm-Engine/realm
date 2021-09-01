#pragma once
#include <math.h>
#define RELAM_ENGINE_FUNC static inline


typedef struct {
	union {
		struct
		{
			float x;
			float y;

		};
		float ptr_raw[2];
	};
} vec2;
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
} vec3;
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
} vec4;



typedef struct {
	union {
		struct {
			vec4 x;
			vec4 y;
			vec4 z;
			vec4 w;
		};
		vec4 ptr_raw[4];
	};
}mat4x4;

typedef vec4 quaternion;

typedef struct re_transform_t
{
	vec3 scale;
	quaternion rotation;
	vec3 euler_rotation;
	vec3 position;

}re_transform_t;


#define PI  3.14159265359
#define new_vec2(x,y) (vec2){x,y}
#define new_vec3(x,y,z)		(vec3){x,y,z}
#define new_vec4(x,y,z,w)	(vec4){x,y,z,w}
#define new_mat4x4(x,y,z,w) (mat4x4){x,y,z,w}
#define vec4_from_vec3(v,w) (vec4){v.x,v.y,v.z,w}
#define vec3_from_vec4(v) (vec3){v.x,v.y,v.z}
#define vec3_up	(vec3){0,1,0}
#define vec3_forward (vec3){0,0,1}
#define vec3_back (vec3){0,0,-1}
#define vec3_right (vec3){1,0,0}
#define vec3_one (vec3){1,1,1}
#define vec4_one (vec4){1,1,1,1}
#define vec2_zero (vec2) {0,0}
#define vec3_zero (vec3){0,0,0}
#define vec4_zero (vec4){0,0,0,0}
#define vec4_up vec4_from_vec3(vec3_up)
#define new_quaternion(x,y,z,w) new_vec4(x,y,z,w)
#define vec4_as_quat(v) (quaternion)v
#define quat_as_vec4(q) (vec4)q
#define quat_as_vec3(q) new_vec3(q.x,q.y,q.z)
#define vec3_to_string(v) printf("X:%f Y:%f Z:%f " ,v.x,v.y,v.z)
#define vec4_to_string(v) "X:%f Y:%f Z:%f W:%f",v.x,v.y,v.z,v.w
#define mat4_zero (mat4x4){vec4_zero,vec4_zero,vec4_zero,vec4_zero}
#define mat4_one (mat4x4){vec4_one,vec4_one,vec4_one,vec4_one}


#define re_cos(x) cosf(x)
#define re_sin(x) sinf(x)
#define re_tan(x) tanf(x)
#define re_sqrt(x) sqrtf(x)
#define re_acos(x) acosf(x);
#define re_asin(x) asinf(x);
#define re_atan(x) atanf(x)
#define re_atan2(x,x2) atan2f(x,x2);
#define re_abs(x) _Generic((x), float:fabsf,int: abs,default: abs)(x)
#define re_copysign(x,y) copysignf(x,y)
#define _DEG_TO_RAD_CONSTANT (float)0.017453
#define _RAD_TO_DEG_CONSTANT (float)57.29577
#define deg_to_rad(a) (a * _DEG_TO_RAD_CONSTANT)
#define rad_to_deg(r) (r * _RAD_TO_DEG_CONSTANT)
#define new_transform ((re_transform_t){vec3_one,new_vec4(0,0,0,1),vec3_zero,vec3_zero})


#define VEC_FUNCTIONS(T,n) \
static inline T T##_scale(const T a, T b) \
{\
	T r;\
	memset(&r,0,sizeof(T));\
	for(int i = 0; i < n; i++)\
	{\
		r.ptr_raw[i] = a.ptr_raw[i] * b.ptr_raw[i];\
	}\
	return r;\
}\
static inline float T##_len(T v)\
{\
	float result = 0;\
	for(int i = 0; i < n; i++)\
	{\
		result += v.ptr_raw[i] * v.ptr_raw[i];\
	}\
	return re_sqrt(result);\
}\
static inline float T##_dot(const T a, const T b)\
{\
	float r = 0;\
	for(int i = 0; i < n; i++)\
	{\
		r+=a.ptr_raw[i] * b.ptr_raw[i];\
	}\
	return r;\
}\
static inline T T##_add(const T a, const T b)\
{\
	T r;\
	memset(&r, 0, sizeof(T));\
	for(int i = 0; i < n;i++)\
	{\
		r.ptr_raw[i] = a.ptr_raw[i] + b.ptr_raw[i];\
	}\
	return r;\
}\
static inline T T##_subtract(const T a, const T b)\
{\
	T r;\
	memset(&r, 0, sizeof(T));\
	for(int i = 0; i < n;i++)\
	{\
		r.ptr_raw[i] = a.ptr_raw[i] - b.ptr_raw[i];\
	}\
	return r;\
}\
static inline T T##_scalar_mul(const T a, float scalar)\
{\
	T r;\
	memset(&r, 0, sizeof(T));\
	for(int i = 0; i < n;i++)\
	{\
		r.ptr_raw[i] = a.ptr_raw[i] * scalar;\
	}\
	return r;\
}\
static inline T T##_normalize(const T v)\
{\
	float len =T##_len(v);\
	if(len == 0)\
	{\
	return v;\
	}\
	float scale = 1.0f / T##_len(v);\
	return T##_scalar_mul(v,scale);\
}\
static inline T T##_square(const T v)\
{\
	T r;\
	memset(&r, 0, sizeof(T));\
	for(int i = 0;i < n; i++)\
	{\
		r.ptr_raw[i] = v.ptr_raw[i] * v.ptr_raw[i];\
	}\
	return r;\
}\

VEC_FUNCTIONS(vec2, 2)
VEC_FUNCTIONS(vec3, 3)
VEC_FUNCTIONS(vec4, 4)

#define vec_add(a,b) _Generic((a), vec2: vec2_add,vec3 : vec3_add, vec4: vec4_add,default:vec4_add)(a,b)

static inline vec3 vec3_cross(vec3 a, vec3 b)
{
	vec3 r;

	r.x = a.y * b.z - a.z * b.y;
	r.y = a.z * b.x - a.x * b.z;
	r.z = a.x * b.y - a.y * b.x;
	return r;

}
static inline vec4 vec4_cross(vec4 a, vec4 b)
{
	vec4 r;

	r.x = a.y * b.z - a.z * b.y;
	r.y = a.z * b.x - a.x * b.z;
	r.z = a.x * b.y - a.y * b.x;
	r.w = 1.0f;
	return r;
}


static inline mat4x4 mat4_mul(const mat4x4 a, const mat4x4 b)
{
	mat4x4 r;
	memset(&r, 0, sizeof(mat4x4));

	for (int i = 0; i < 4; i++)
	{


		for (int j = 0; j < 4; j++)
		{
			for (int k = 0; k < 4; k++)
			{
				r.ptr_raw[i].ptr_raw[j] += a.ptr_raw[k].ptr_raw[j] * b.ptr_raw[i].ptr_raw[k];

			}


		}
	}
	return r;


}





static inline vec4 mat4_mul_vec4(const mat4x4 M, const vec4 v)
{
	vec4 r;
	memset(&r, 0, sizeof(vec4));
	for (int j = 0; j < 4; j++)
	{

		for (int i = 0; i < 4; i++)
		{
			r.ptr_raw[j] += M.ptr_raw[i].ptr_raw[j] * v.ptr_raw[i];

		}
	}
	return r;


}

static inline mat4x4 re_perspective(float fov, float aspectRatio, float near, float far)
{

	float scale = tanf(fov * 0.5f);
	float r = aspectRatio * scale;
	float l = -r;
	float t = scale;
	float b = -t;
	mat4x4 M;
	memset(&M, 0, sizeof(mat4x4));
	M.x.x = scale / aspectRatio;
	M.y.y = scale;
	M.z.z = -((far + near) / (far - near));
	M.z.w = -1;
	M.w.z = -((2 * far * near) / (far - near));

	return M;

}

static inline mat4x4 re_orthographic(float right, float left, float top, float bottom, float near, float far)
{
	mat4x4 orthoMat;
	memset(&orthoMat, 0, sizeof(mat4x4));
	orthoMat.x.x = 2.0f / (right - left);

	orthoMat.y.y = 2 / (top - bottom);
	orthoMat.z.z = -2 / (far - near);
	orthoMat.w.x = -(right + left) / (right - left);
	orthoMat.w.y = -(top + bottom) / (top - bottom);
	orthoMat.w.z = -(far + near) / (far - near);
	orthoMat.w.w = 1.0f;
	return orthoMat;

}

static inline mat4x4 re_mat4_identity()
{
	mat4x4 mat;
	mat.x = new_vec4(1, 0, 0, 0);
	mat.y = new_vec4(0, 1, 0, 0);
	mat.z = new_vec4(0, 0, 1, 0);
	mat.w = new_vec4(0, 0, 0, 1);
	return mat;

}

static inline mat4x4 mat4_lookat(const vec3 eye, const vec3 centre, const vec3 up)
{
	vec3 f = vec3_subtract(centre, eye);
	f = vec3_normalize(f);
	vec3 s = vec3_cross(up, f);
	s = vec3_normalize(s);
	vec3 u = vec3_cross(f, s);
	vec4 r1 = new_vec4(s.x, u.x, f.x, 0.0f);
	vec4 r2 = new_vec4(s.y, u.y, f.y, 0.0f);
	vec4 r3 = new_vec4(s.z, u.z, f.z, 0.0f);
	vec4 r4 = new_vec4(0, 0, 0, 1.0f);
	mat4x4 orientation = new_mat4x4(r1, r2, r3, r4);
	mat4x4 translation = re_mat4_identity();
	translation.w = new_vec4(-eye.x, -eye.y, -eye.z, 1.0f);
	return mat4_mul(orientation, translation);



}

static inline mat4x4 mat4_rotate_x(const mat4x4 M, float angle)
{
	mat4x4 mat = re_mat4_identity();

	memset(&mat, 0, sizeof(mat4x4));
	float c = re_cos(angle);
	float s = re_sin(angle);
	mat.x.x = 1.0f;
	mat.y.y = c;
	mat.y.z = s;
	mat.z.y = -s;
	mat.z.z = c;
	return mat4_mul(M, mat);


}
static inline mat4x4 mat4_rotate_y(const mat4x4 M, float angle)
{
	mat4x4 mat = re_mat4_identity();


	float c = re_cos(angle);
	float s = re_sin(angle);
	mat.x.x = c;
	mat.x.z = -s;
	mat.z.x = s;
	mat.z.z = c;

	return mat4_mul(M, mat);
}

static inline mat4x4 mat4_rotate_z(const mat4x4 M, float angle)
{
	mat4x4 mat = re_mat4_identity();


	float c = re_cos(angle);
	float s = re_sin(angle);
	mat.x.x = c;
	mat.x.y = s;
	mat.y.x = -s;
	mat.y.y = c;
	return mat4_mul(M, mat);
}

static inline mat4x4 mat4_scale(const mat4x4 M, vec3 s)
{
	mat4x4 mat = mat4_one;
	mat.x = vec4_scalar_mul(M.x, s.x);
	mat.y = vec4_scalar_mul(M.y, s.y);
	mat.z = vec4_scalar_mul(M.z, s.z);
	mat.w = M.w;
	return mat;



}

static inline mat4x4 mat4_translate(const mat4x4 M, vec3 v)
{
	mat4x4 mat;
	memcpy(&mat, &M, sizeof(mat4x4));
	mat.w.x = v.x;
	mat.w.y = v.y;
	mat.w.z = v.z;
	mat.w.w = 1.0f;
	return mat;

}

static inline mat4x4 mat4_transpose(const mat4x4 M)
{
	mat4x4 result = mat4_zero;
	int i, j;
	for (j = 0; j < 4; ++j)
		for (i = 0; i < 4; ++i)
			result.ptr_raw[i].ptr_raw[j] = M.ptr_raw[j].ptr_raw[i];
	return result;

}

static inline mat4x4 mat4_inverse(const mat4x4 M)
{
	float s[6];
	float c[6];


	s[0] = M.x.x * M.y.y - M.y.x * M.x.y;
	s[1] = M.x.x * M.y.z - M.y.x * M.x.z;
	s[2] = M.x.x * M.y.w - M.y.x * M.x.w;
	s[3] = M.x.y * M.y.z - M.y.y * M.x.z;
	s[4] = M.x.y * M.y.w - M.y.y * M.x.w;
	s[5] = M.x.y * M.y.w - M.y.z * M.x.w;

	c[0] = M.z.x * M.w.y - M.w.x * M.z.y;
	c[1] = M.z.x * M.w.z - M.w.x * M.z.z;
	c[2] = M.z.x * M.w.w - M.w.x * M.z.w;
	c[3] = M.z.y * M.w.y - M.w.y * M.z.z;
	c[4] = M.z.y * M.w.w - M.w.y * M.z.w;
	c[5] = M.z.z * M.w.w - M.w.z * M.z.w;

	float idet = 1.0f / (s[0] * c[5] - s[1] * c[4] + s[2] * c[3] + s[3] * c[2] - s[4] * c[1] + s[5] * c[0]);

	mat4x4 r;
	r.x.x = (M.y.y * c[5] - M.y.z * c[4] + M.y.w * c[3]) * idet;
	r.x.y = (-M.x.y * c[5] + M.x.y * c[4] - M.x.w * c[3]) * idet;
	r.x.z = (M.w.y * s[5] - M.w.z * s[4] + M.w.w * s[3]) * idet;
	r.x.w = (-M.z.y * s[5] + M.z.z * s[4] - M.z.w * s[3]) * idet;
	
	r.y.x = (-M.y.x * c[5] + M.y.z * c[2] - M.y.w * c[1]) * idet;
	r.y.y = (M.x.x * c[5] - M.x.z * c[2] + M.x.w * c[1]) * idet;
	r.y.z = (-M.w.x * s[5] + M.w.z * s[2] - M.w.w * s[1]) * idet;
	r.y.w = (M.z.x * s[5] - M.z.z * s[2] + M.z.w * s[1]) * idet;
	
	r.z.x = (M.y.x * c[4] - M.y.y * c[2] + M.y.w * c[0]) * idet;
	r.z.y = (-M.x.x * c[4] + M.x.y * c[2] - M.x.w * c[0]) * idet;
	r.z.z = (M.w.x * s[4] - M.w.y * s[2] + M.w.w * s[0]) * idet;
	r.z.w = (-M.z.x * s[4] + M.z.y * s[2] - M.z.w * s[0]) * idet;
	
	r.w.x = (-M.y.x * c[3] + M.y.y * c[1] - M.y.z * c[0]) * idet;
	r.w.y = (M.x.x * c[3] - M.x.y * c[1] + M.x.z * c[0]) * idet;
	r.w.z = (-M.w.x * s[3] + M.w.y * s[1] - M.w.z * s[0]) * idet;
	r.w.w = (M.z.x * s[3] - M.z.y * s[1] + M.z.z * s[0]) * idet;


	return r;




}


static inline quaternion quat_mul(const quaternion a, const quaternion b)
{
	quaternion R;
	memset(&R, 0, sizeof(quaternion));
	R.x = a.x * b.w + a.y * b.z - a.z * b.y + a.w * b.x;
	R.y = a.y * b.w + a.z * b.x + a.w * b.y - a.x * b.z;
	R.z = a.z * b.w + a.w * b.z + a.x * b.y - a.y * b.x;
	R.w = a.w * b.w - a.x * b.x - a.y * b.y - a.z * b.z;
	return R;
}

static inline vec3 quat_rotate_vec3(const quaternion Q, const vec3 v)
{
	vec3 b = quat_as_vec3(Q);
	float b2 = b.x * b.x + b.y * b.y + b.z * b.z;
	vec3 R = vec3_scalar_mul(v, (Q.w * Q.w - b2));
	R = vec3_add(R, vec3_scalar_mul(b, (vec3_dot(v, b) * 2.0f)));
	R = vec3_add(R, vec3_scalar_mul(vec3_cross(b, v), Q.w * 2.0f));
	return R;


}

static inline mat4x4 quat_rotation_matrix(const quaternion Q)
{
	mat4x4 R = mat4_zero;

	vec3 b = quat_as_vec3(Q);
	float c = Q.w;
	vec3 b2 = vec3_square(b);
	float xx = 1.0f - 2.0f * (b2.y + b2.z);
	float xy = 2.0f * ((b.x * b.y) - (c * b.z));
	float xz = 2.0f * ((b.x * b.z) + (c * b.y));
	float yx = 2.0f * ((b.x * b.y) + (c * b.z));
	float yy = 1.0f - 2.0f * (b2.x + b2.z);
	float yz = 2.0f * ((b.y * b.z) - (c * b.x));
	float zx = 2.0f * ((b.x * b.y) - (c * b.y));
	float zy = 2.0f * ((b.y * b.z) + (c * b.x));
	float zz = 1.0f - 2.0f * (b2.x + b2.y);
	vec4 r1 = new_vec4(xx, xy, xz, 0);
	vec4 r2 = new_vec4(yx, yy, yz, 0);
	vec4 r3 = new_vec4(zx, zy, zz, 0);
	vec4 r4 = new_vec4(0, 0, 0, 1);
	R = new_mat4x4(r1, r2, r3, r4);
	return R;

}

static inline mat4x4 compute_transform(re_transform_t transform)
{
	mat4x4 M = re_mat4_identity();
	M = mat4_scale(M, transform.scale);
	/*M = mat4_rotate_x(M, transform.euler_rotation.x);
	M = mat4_rotate_y(M, transform.euler_rotation.y);
	M = mat4_rotate_z(M, transform.euler_rotation.z);*/
	quaternion normalized_rotation = vec4_normalize(transform.rotation);
	mat4x4 rotation = quat_rotation_matrix(normalized_rotation);

	M = mat4_mul(M, rotation);
	M = mat4_translate(M, transform.position);
	return M;

}

static inline vec3 quat_to_euler(quaternion Q)
{
	float yaw = 0;
	float pitch = 0;
	float roll = 0;

	float sinr_cosp = 2 * (Q.w * Q.x + Q.y * Q.z);
	float cosr_cosp = 1 - 2 * (Q.x * Q.x + Q.y * Q.y);
	roll = re_atan2(sinr_cosp, cosr_cosp);

	float sinp = 2 * (Q.w * Q.y - Q.z * Q.x);



	pitch = re_asin(sinp);


	float siny_cosp = 2 * (Q.w * Q.z + Q.x * Q.y);
	float cosy_cosp = 1 - 2 * (Q.y * Q.y + Q.z * Q.z);
	yaw = re_atan2(siny_cosp, cosy_cosp);
	return new_vec3(roll, pitch, yaw);

}

static inline quaternion euler_to_quat(vec3 euler)
{
	float pitch = euler.y;
	float yaw = euler.z;
	float roll = euler.x;
	float cy = re_cos(yaw * 0.5f);
	float sy = re_sin(yaw * 0.5f);
	float cp = re_cos(pitch * 0.5f);
	float sp = re_sin(pitch * 0.5f);
	float cr = re_cos(roll * 0.5f);
	float sr = re_sin(roll * 0.5f);

	quaternion q;
	q.w = cr * cp * cy + sr * sp * sy;
	q.x = sr * cp * cy - cr * sp * sy;
	q.y = cr * sp * cy + sr * cp * sy;
	q.z = cr * cp * sy - sr * sp * cy;
	return q;


}




