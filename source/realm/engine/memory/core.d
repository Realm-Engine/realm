module realm.engine.memory.core;

import std.traits;

package
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

interface Allocator
{
	T* allocate(T)(size_t count);

}

package size_t alignForward(size_t Alignment = (2 * (void*).sizeof))(ref size_t ptr)
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


package const char[6] MAGIC_BYTES = "RIPLEY";


package static class MemoryUtil
{
	struct MemoryHeader
	{
		const char[6] magicBytes;
		size_t offset;
		size_t size;
	}

	void* allocate(size_t size) nothrow
	{
		size_t totalSize = MemoryHeader.sizeof + size;
		void* ptr = malloc(totalSize);
		return ptr;
		
		
	}

}

