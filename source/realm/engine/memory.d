module realm.engine.memory;

private
{
	import core.stdc.stdio;
	import core.stdc.stdlib;
	import std.conv;
	import core.stdc.string;
	import std.meta;
	import std.range;
	import std.array;
	import std.traits;
}

enum bool isPowerOfTwo(size_t x) = (x & (x-1)) == 0;


alias MemoryInterface = AliasSeq!("allocate","deallocate");

class RealmPoolAllocator(T)
{
	
	private ubyte[] buffer;
	private T*[] freeStack;
	private size_t stackIndex;
	private size_t size;
	enum ChunkSize = __traits(classInstanceSize,T);
	enum ChunkAlignment = classInstanceAlignment!(T);
	private size_t alignedChunkSize;
	this(size_t size)
	{
		this.size = size;
		auto typeInfo = typeid(T);
		
		alignedChunkSize = ChunkSize;
		size_t diff = alignForward!(ChunkAlignment)(alignedChunkSize);
		//chunkSize -= diff;
		buffer = (cast(ubyte*)malloc(alignedChunkSize * size))[0..size*alignedChunkSize];
		freeStack = (cast(T**)malloc((T*).sizeof * size))[0..size];
		free();
		
	}

	T* allocate(Args...)( Args args)
	in
	{
		assert(stackIndex >=0,"Out of memory.");
	}
	do
	{
		
		T* ptr = freeStack[stackIndex];
		printf("%p",ptr);
		size_t ptrSizeT = cast(size_t)ptr;
		size_t index = (size-1) - ((cast(size_t)&buffer[(alignedChunkSize * (size - 1))]) - ptrSizeT)/ alignedChunkSize;
		ubyte[] chunk = buffer[(alignedChunkSize * index)..((alignedChunkSize * index) + alignedChunkSize)];
		
		emplace!T(chunk,args);
		stackIndex--;
		return ptr;
	}

	void deallocate(T* ptr)
	{
		freeStack[stackIndex++] = ptr;
		destroy(*ptr);
	}

	void free()
	{

		auto typeInfo = typeid(T);
		for(int i = 0; i < freeStack.length;i++)
		{
			
			
			freeStack[i] = cast(T*)&buffer[(alignedChunkSize * i)];
		}
		stackIndex = size - 1;

	}



}

private size_t alignForward(size_t Alignment = (2 * (void*).sizeof))(ref size_t ptr)
{
	static assert(isPowerOfTwo!(Alignment));
	size_t initial = ptr;
	size_t temp = ptr;
	size_t mod = temp & (Alignment - 1);
	if(mod != 0)
	{
		ptr += Alignment - mod;
	}
	return initial-ptr;
}


class RealmArenaAllocator 
{
	
	private ubyte[] buffer;
	private size_t offset;
	this(size_t size) nothrow @nogc
	{
		buffer = (cast(ubyte*)malloc(size))[0..size];
		offset = 0;
	}

	
	private ubyte[] allocateAligned(T)(size_t count) nothrow @nogc
	{
		size_t ptr = cast(size_t)buffer.ptr + offset;

		alignForward(ptr);
		ptr -= cast(size_t)buffer.ptr;
		printf("%d",ptr);
		size_t length = __traits(initSymbol,T).length * count;
		printf("%d",length);
		if(length + ptr <= buffer.length)
		{
			auto mem = buffer[offset .. offset + length];
			memset(mem.ptr,0,length);
			offset += ptr + length;
			return mem;

		}
		return null;
	}

	ubyte[] allocate(T)(size_t count) nothrow @nogc
	{
		return allocateAligned!(T)(count);
	}

	void deallocate()
	{
		offset = 0;

	}
	

}




class MemoryUtils
{
	import core.lifetime;
	static void initializeMemory(T,Args...)(T* ptr, Args args)
	{
		emplace!(T)(ptr,args);
	}


}