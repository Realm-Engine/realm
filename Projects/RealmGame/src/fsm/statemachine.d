module realm.fsm.statemachine;
import realm.engine.container.stack;
import realm.fsm.gamestate;
class StateMachine
{
	private Stack!(GameState) _stack;
	
	this()
	{
		_stack = new Stack!(GameState)(16);
	}

	void pushState(GameState t)
	{
		t.enter();
		_stack.push(t);

	}

	void changeState(GameState t)
	{
		if(!_stack.empty)
		{
			GameState oldState = _stack.pop();
			oldState.finish();
		}
		pushState(t);
	}
	void popState()
	{
		if(!_stack.empty)
		{
			GameState oldState = _stack.pop();
			oldState.finish();
		}
	}

	GameState top()
	{
		if(!_stack.empty)
		{
			return _stack.peek();
		}
		return null;
	}

}

