module realm.engine.container.queue;

private
{
	import realm.engine.container.stack;

}

class Queue(T)
{
	private Stack!(T) _stack1;
	private Stack!(T) _stack2;
	

	this(uint len)
	{
		_stack1 = new Stack!(T)(len);
		_stack2 = new Stack!(T)(len);
	}

	void enqueue(T t) nothrow @nogc
	{
		_stack1.push(t);
	}
	
	@property bool empty()
	{
		return _stack1.empty && _stack2.empty;
	}

	T peek() nothrow @nogc
	{
		if(_stack2.empty)
		{
			while(!_stack1.empty)
			{
				_stack2.push(_stack1.pop());
			}
		}
		return _stack2.peek();
	}
	T* peekRef() nothrow @nogc
	{
		if(_stack2.empty)
		{
			while(!_stack1.empty)
			{
				_stack2.push(_stack1.pop());
			}
		}
		return _stack2.peekRef();
	}

	T dequeue() nothrow
	{
		if(_stack2.empty)
		{
			while(!_stack1.empty)
			{
				_stack2.push(_stack1.pop());
			}
		}

		return _stack2.pop();
	}

}
