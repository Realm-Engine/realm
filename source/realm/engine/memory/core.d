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
	import realm.engine.logging;
	
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
		size_t diff = Alignment - mod;
		ptr += diff;
	}
	return ptr - initial;
}


package const char[6] MAGIC_BYTES = "RIPLEY";
alias Alignment = Alias!(2 * (void*).sizeof);
struct MemoryHeader
{
	char[6] magicBytes;
	size_t offset;
	size_t size;
	size_t forwardAlignment;


}
static class MemoryUtil
{
	static bool isValidHeader( MemoryHeader header) 
	{
		return (header.magicBytes == MAGIC_BYTES);
	}

	static void* allocateChunk(size_t size) nothrow @nogc
	{
		size_t headerSize = MemoryHeader.sizeof + (Alignment - 1);
		size_t totalSize = headerSize + size;
		void* chunk = malloc(totalSize);
		if(chunk is null)
		{
			error("Could not allocate memory of size %d", size);
		}
		MemoryHeader hdr;
		hdr.magicBytes = MAGIC_BYTES;
		void* userDataPtr = (chunk+headerSize);
		size_t ptrAligned = cast(size_t)userDataPtr;
		size_t forwardAmount = alignForward!(Alignment)(ptrAligned);
		userDataPtr = cast(void*)ptrAligned;
		hdr.offset = headerSize + forwardAmount;
		hdr.size = size;
		hdr.forwardAlignment = forwardAmount;
		memcpy(chunk,&hdr,MemoryHeader.sizeof);
		
		memcpy(userDataPtr - size_t.sizeof,&forwardAmount,size_t.sizeof);
		info("Allocated %lu bytes of memory at %p",size,userDataPtr);
		return userDataPtr;
		
		
	}


	

	static MemoryHeader getHeader(void* chunk) nothrow @nogc
	{
		scope(failure)
		{
			error("Chunk at %p is not a valid memory chunk",chunk);
		}
		size_t hdrSize =  MemoryHeader.sizeof + (Alignment - 1);
		size_t forwardAmount = * (cast(size_t*)(chunk-size_t.sizeof));
		void* hdrPtr = chunk - (hdrSize + forwardAmount);
		
		MemoryHeader header = *(cast(MemoryHeader*)hdrPtr[0..MemoryHeader.sizeof]);

		if(header.magicBytes != MAGIC_BYTES)
		{
			error("Chunk at %p is not a valid memory chunk",chunk);
		}		
		return header;
		
	}

	static void resizeChunk(void* chunk,size_t size)
	{
		scope(failure)
		{
			error("Could not resize memory chunk at %p",chunk);
		}
		MemoryHeader header = getHeader(chunk);
		bool valid = isValidHeader(header);
		
		if(!valid)
		{
			error("Memory chunk at %p is not valid, will not resize",chunk);
		}
		


		void* ptr = chunk-header.offset;
		if(ptr is null)
		{
			error("Could not resize memory chunk at %p",chunk);
			return;
		}

		ptr = realloc(ptr,size);
		header.size = size;
		memcpy(ptr,&header,MemoryHeader.sizeof);

	}

	static void freeChunk(void* chunk)
	{
		
		scope(failure)
		{
			error("Chunk at %p is not a valid memory chunk",chunk);
		}
		MemoryHeader header = getHeader(chunk);
		if(!isValidHeader(header))
		{
			error("Chunk at %p is not a valid memory chunk, will not be freed",chunk);
			return;
		}
		void* ptr = chunk - header.offset;
		info("Freed allocated chunk at %p",chunk);
		free(ptr);
		
	}

}

