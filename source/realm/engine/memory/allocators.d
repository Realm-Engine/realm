module realm.engine.memory.allocators;

private
{

	import realm.engine.memory.core;

}


class RealmArenaAllocator 
{

	private void[] buffer;
	private size_t offset;
	private size_t prevOffset;
	this(size_t size) nothrow @nogc
	{
		buffer = MemoryUtil.allocateChunk(size)[0..size];
		offset = 0;
		prevOffset = 0;
	}


	private void[] allocateAligned(T)(size_t count) nothrow @nogc
	{
		size_t ptr = cast(size_t)buffer.ptr + offset;

		alignForward(ptr);
		ptr -= cast(size_t)buffer.ptr;
		size_t length = __traits(initSymbol,T).length * count;
		if(length + ptr <= buffer.length)
		{
			auto mem = buffer[offset .. offset + length];
			memset(mem.ptr,0,length);
			prevOffset = offset;
			offset += ptr + length;
			return mem;

		}
		return null;
	}




	void[] allocate(T)(size_t count) nothrow @nogc
	{
		return allocateAligned!(T)(count);
	}

	void deallocate()
	{
		offset = 0;

	}


}
