module realm.engine.container.stack;
import std.traits;
private
{

	import realm.engine.memory;
}
class Stack(T, size_t Size = 0,alias A = RealmArenaAllocator) 
{
	//static assert(__traits(isTemplate,A));
	private A allocator;

	
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
	

	this(A allocator)
	{
		this.allocator = allocator;
	}
	
	static if(!isFixedSize)
	{
		this(size_t len,A allocator,float growthFactor = 1.5f)
		{
			
			this.allocator = allocator;

			this.growthFactor = growthFactor;
			
			arr = cast(T[]) allocator.allocate!(T)(len);
			index = 0;
		}
	}

	

	void push(T val) nothrow @nogc
	in(index <= arr.length)
	{
		
		
		static if(!isFixedSize)
		{
			if(index == arr.length)
			{
				
				//arr = Allocator.reallocate!(T)(arr.ptr,cast(size_t)(cast(float)arr.length * growthFactor));
			}
		}
		arr[++index] = val;
		
		
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

	@property full() nothrow @nogc
	{
		return arr.length -1 == index;
	}

	~this()
	{
		static if(!isFixedSize)
		{
			allocator.deallocate();
		}
	}


}
