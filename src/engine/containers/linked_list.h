#ifndef LINKED_LIST_H
#define LINKED_LIST_H



#define linked_list_decl(T)\
typedef struct _##T##_node\
{ \
	struct _##T##_node * next;\
	T value;\
}_##T##_node;\
static  _##T##_node* _linked_list_##T##_enumerate_func(_##T##_node* current, T* val)\
{\
	if(current->next == NULL)\
	{\
		return NULL;\
	}\
	*val = current->next->value;\
	return current->next;\
}\
static  _##T##_node* _##T##_node_create(T val)\
{\
	_##T##_node* node = (_##T##_node*)malloc(sizeof(_##T##_node));\
	node->value = val;\
	node->next = NULL;\
	return node;\
}\
typedef struct _linked_list_##T\
{\
	_##T##_node * _head;\
} _linked_list_##T;\
static  _##T##_node* _linked_list_##T##_append(_linked_list_##T * ll,T value)\
{\
	_##T##_node* current = ll->_head;\
	if(current == NULL)\
	{\
		ll->_head = _##T##_node_create(value);\
		return ll->_head;\
	}\
	while(current->next != NULL)\
	{\
		current = current->next;\
	}\
	current->next = _##T##_node_create(value);\
	return current->next;\
}\
static  void _linked_list_##T##_free(_linked_list_##T * ll)\
{\
	_##T##_node* current = ll->_head;\
	while(current != NULL)\
	{\
		_##T##_node* temp = current;\
		current = current->next;\
		free(temp);\
	}\
}\

#define linked_list(T) _linked_list_##T
#define linked_list_append(T,ll,v) _linked_list_##T##_append(ll,v);
#define linked_list_traverse(T,v,e)\
T v = (e)._head->value;\
_##T##_node* i;\
for(i = (e)._head;i != NULL; i = _linked_list_##T##_enumerate_func((i),(&v)))
#define linked_list_free(T,ll) _linked_list_##T##_free(ll);
#endif // !LINKED_LIST_H