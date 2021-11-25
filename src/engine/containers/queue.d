module realm.engine.containers.queue;




private class Node(T)
{
	T item;
	Node!T next;
	this(T item,Node!T  next = null)
	{
		this.item = item;
		this.next = next;
	}
}
class Queue(T)
{
	
	private Node!T  frontNode;
	private Node!T  backNode;
	private uint count;
	
	
	this()
	{
		frontNode = null;
		backNode = null;
		count = 0;
	}

	void enqueue(T item)
	{
		Node!T newNode = new Node!T(item,null);
		if(empty())
		{
			frontNode = newNode;
			backNode = newNode;
		}
		else
		{
			backNode.next = newNode;
			backNode = backNode.next;
		}
		count++;
	}
	
	T dequeue()
	{
		T result = T.init;
		if(!empty())
		{
			result = frontNode.item;
			frontNode = frontNode.next;
			count--;
		}
		return result;
	}
	T front()
	{
		T result = T.init;
		if(!empty())
		{
			result = frontNode.item;

		}
		return result;
	}
	

	bool empty()
	{
		return count == 0;
	}

	uint size()
	{
		return count;
	}

}

