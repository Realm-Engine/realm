module realm.engine.terminal.core;
package
{
	import core.vararg;
}

enum TerminalColor :ushort
{
	RED = 4u,
	GREEN = 2u,
	BLUE = 1u,
	WHITE = RED | GREEN | BLUE
}

package interface ITerminal
{

	void write(const(char*) str ) nothrow @nogc;
	
	void write(const(char*) str, ...) nothrow @nogc;
	void setColor(TerminalColor color) nothrow @nogc;


}