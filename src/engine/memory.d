module realm.engine.memory;




class RealmResource(T)
{
	private T object;
	alias object this;
	

	static RealmResource!T create()
	{
		return new RealmResource!T;
	}
	static RealmResource!T createShared()
	{
		return new shared(RealmResource!T);
	}

}


