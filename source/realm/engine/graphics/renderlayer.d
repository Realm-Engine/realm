module realm.engine.graphics.renderlayer;
import realm.engine.graphics.core;
import realm.engine.graphics.material;



abstract class RenderLayer
{
	abstract void initialize();
	abstract void flush();

	
}