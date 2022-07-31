module realm.engine.memory;





template RealmHeapAllocator(T)
{
	
	import core.stdc.stdlib;
	import realm.engine.logging;
	T[] allocate(size_t length) nothrow @nogc
	in(length != 0, "Cant allocate size of '0'")
	{
		T* ptr = cast(T*)malloc(length * T.sizeof);
		assert(ptr !is null,"Out of memory!");
		return (ptr[0..length]);
	}

	T[] reallocate(T* ptr,size_t newLength) nothrow @nogc
	in(newLength >= 0, "Cant reallocate to negative size")
	{
		T* newPtr = cast(T*)realloc(ptr,newLength * T.sizeof);
		assert(newPtr !is null, "Out of memory");
		
		return newPtr[0..newLength];
	}

	void deallocate(T* ptr) nothrow @nogc
	{
		free(ptr);
	}
	


}
