module realm.engine.memory;

private
{
	import core.stdc.stdio;
	import core.stdc.stdlib;
	import std.conv;
	import core.stdc.string;
	import std.meta;
}

enum bool isPowerOfTwo(size_t x) = (x & (x-1)) == 0;


alias MemoryInterface = AliasSeq!("allocate","deallocate");



private void alignForward(size_t Alignment = (2 * (void*).sizeof))(ref size_t ptr)
{
	static assert(isPowerOfTwo!(Alignment));

	size_t temp = ptr;
	size_t mod = temp & (Alignment - 1);
	if(mod != 0)
	{
		ptr += Alignment - mod;
	}
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