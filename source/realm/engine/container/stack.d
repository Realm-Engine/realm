module realm.engine.container.stack;

class Stack(T)
{
	private T[] arr;
	private int index;
	this(size_t len)
	{
		arr.length = len;
		index = -1;
	}

	void push(T val) nothrow @nogc
	in(index < cast(long)arr.length)
	{
		index++;
		arr[index] = val;
		
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

	@property bool empty() nothrow @nogc
	{
		return index < 0;
	}






}
