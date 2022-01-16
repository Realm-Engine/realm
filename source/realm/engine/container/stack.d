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

	void push(T val)
	in(index < cast(long)arr.length)
	{
		index++;
		arr[index] = val;
		
	}

	T pop()
	in(index >= 0, "Trying to pop empty stack")
	do
	{
		T val = arr[index];
		index--;
		return val ;

	}

	T peek()
	in(index >=0 && index < arr.length ,"Stack out of range")
	{
		return arr[index];
	}

	@property bool empty()
	{
		return index < 0;
	}






}
