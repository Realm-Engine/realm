#ifndef VECTOR_H
#define VECTOR_H

#define vector(T) _vector_##T
#define vector_decl(T)\
\
typedef struct vector(T)\
{\
	T* elements;\
	size_t count;\
	size_t capacity;\
}vector(T);\
static vector(T) _new_vector_##T(size_t reserve)\
{\
	vector(T) v;\
	v.elements = (T *)malloc(sizeof(T) * reserve);\
	memset(v.elements,0,sizeof(T) * reserve);\
	v.capacity = reserve;\
	v.count = 0;\
	return v;\
}\
static  void _vector_##T##_resize(vector(T) * vector, size_t size)\
{\
	vector->capacity = size;\
	vector->elements = ( T *)realloc(vector->elements,sizeof( T ) * size);\
}\
static  T * _vector_##T##_insert(vector(T) * vector,int i,T value)\
{\
	while(i > vector->capacity)\
	{\
		size_t resize_amount = 0;\
		if(vector->capacity == 0)\
		{\
			resize_amount = _RE_VECTOR_CHUNK_SIZE;\
		}\
		else\
		{\
			int mod = _RE_VECTOR_CHUNK_SIZE % vector->capacity;\
			resize_amount = mod + vector->capacity;\
		}\
		_vector_##T##_resize(vector, resize_amount); \
	}\
	vector->elements[vector->count] = value; \
	T * new_element = &vector->elements[vector->count];\
	vector->count += 1;\
	return new_element;\
}\
static void _vector_##T##_append_range(vector(T) * vector, T * arr, size_t count)\
{\
	while(count + vector->count > vector->capacity) \
	{\
		size_t resize_amount = 0;\
		if(vector->capacity == 0)\
		{\
			resize_amount = _RE_VECTOR_CHUNK_SIZE;\
		}\
		else\
		{\
			int mod = _RE_VECTOR_CHUNK_SIZE % vector->capacity;\
			resize_amount = mod + vector->capacity;\
		}\
		_vector_##T##_resize(vector, resize_amount); \
	}\
	memcpy(&(vector->elements[vector->count]),arr, count * sizeof(T));\
	vector->count += count;\
}\
static T * _vector_##T##_append(vector(T) * vector, T value)\
{\
	return _vector_##T##_insert(vector, vector->count + 1,value); \
}\
static  T _vector_##T##_get(vector(T)* vector, size_t index )\
{\
	return vector->elements[index];\
}\
static  void _vector_##T##_set(vector(T)* vector, size_t index, T value )\
{\
	vector->elements[index] = value;\
}\
static  void _vector_##T##_free(vector(T)* vector)\
{\
	free(vector->elements);\
}\

#define vector_insert(T,vector,idx,value) _vector_##T##_insert(vector,idx,value)
#define new_vector(T,size) _new_vector_##T(size)
#define vector_resize(T,vector,size) _vector_##T##_resize(vector,size)
#define vector_get(T,vector,index) _vector_##T##_get(vector,index)
#define vector_set(T,vector,index,value) _vector_##T##_get(vector,index,value)
#define vector_free(T,vector) _vector_##T##_free(vector)
#define vector_append(T, vector,v) _vector_##T##_append(vector,v)
#define vector_append_range(T,vector,arr,count) _vector_##T##_append_range(vector, arr, count)
#endif // !VECTOR_H