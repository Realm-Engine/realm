module realm.engine.graphics.renderlayer;
import realm.engine.graphics.core;
import realm.engine.graphics.material;



abstract class RenderLayer
{
    abstract void initialize();
    abstract void onDraw(string RenderpassName, Renderpass)(Renderpass pass);

    void bindAttributes(T)()
    {
        import realm.engine.graphics.opengl : bindAttribute;
        import std.meta;

        T vertex;
        uint stride = 0;

        stride += T.sizeof;

        int offset = 0;
        int index = 0;
        static foreach (member; __traits(allMembers, T))
        {

            bindAttribute!(Alias!(typeof(__traits(getMember, vertex, member))))(index,
                    offset, stride);
            index += 1;
            offset += (typeof(__traits(getMember, vertex, member))).sizeof;
        }
    }

}