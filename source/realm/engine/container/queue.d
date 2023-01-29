module realm.engine.container.queue;
import realm.engine.logging;
private
{
	import realm.engine.memory;
	import realm.engine.container.stack;

}

class Queue(T,size_t Size = 0,alias A = RealmArenaAllocator)
{

	

	private Stack!(T,Size,A) _stack1;
	private Stack!(T,Size,A) _stack2;
	

	this(uint len,A allocator)
	{
		_stack1 = new Stack!(T)(len, allocator);
		_stack2 = new Stack!(T)(len, allocator);
	}

	///Put item on end of queue
	void enqueue(T t) nothrow @nogc
	{
		if(!_stack1.full)
		{
			_stack1.push(t);
		}
		
	}
	
	@property bool empty()
	{
		return _stack1.empty && _stack2.empty;
	}

	///Returns first item on queue without removing from queue
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
	///Returns reference to first item on queue without removing it
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

	///Removes first item from queue
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
