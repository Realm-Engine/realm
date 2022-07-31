module realm.engine.container.stack;
import std.traits;
private
{
	import realm.engine.memory;
}
class Stack(T, size_t Size = 0,alias A = RealmHeapAllocator) 
{
	
	static assert(__traits(isTemplate,A));
	enum isClassAllocator = __traits(isFinalClass,A!(T));
	static if(isClassAllocator == true)
	{
		
		private A!(T) allocator;
		alias Allocator = allocator;
		
	}
	else
	{
		alias Allocator = A!(T);
		
	}

	
	enum isFixedSize = Size > 0;
	static if(isFixedSize)
	{
		private T[Size] arr;
	}
	else
	{
		private T[] arr;
		private float growthFactor;

	}

	
	private size_t index;
	


	
	static if(!isFixedSize)
	{
		this(size_t len,float growthFactor = 1.5f)
		{
			static if(isClassAllocator == true)
			{

				Allocator = new A!(T);
			}
			this.growthFactor = growthFactor;
			arr = Allocator.allocate(len);
			index = 0;
		}
	}

	

	void push(T val) nothrow @nogc
	in(index < arr.length)
	{
		
		arr[++index] = val;
		static if(!isFixedSize)
		{
			if(index == arr.length)
			{

				arr = Allocator.reallocate(arr.ptr,cast(size_t)(cast(float)arr.length * growthFactor));
			}
		}

		
		
	}

	T pop() nothrow @nogc
	in(index >= 0, "Trying to pop empty stack")
	do
	{
		T val = arr[index];
		index--;
		return val ;

	}

	T peek() nothrow @nogc
	in(index >=0 && index < arr.length ,"Stack out of range")
	{
		return arr[index];
	}

	T* peekRef() nothrow @nogc
	in(index >=0 && index < arr.length ,"Stack out of range")
	{
		return &arr[index];
	}

	@property bool empty() nothrow @nogc
	{
		return index == 0;
	}

	@property length() nothrow @nogc
	{
		return index;
	}
	
	@property capacity() nothrow @nogc
	{
		return arr.length;
	}

	~this()
	{
		static if(!isFixedSize)
		{
			Allocator.deallocate(arr.ptr);
		}
	}


}
