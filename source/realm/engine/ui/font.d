module realm.engine.ui.font;
private
{
    import bindbc.freetype;
    import realm.engine.logging;
    import std.string;
    import imagefmt;
    import std.conv;
}

private static FT_Library ft;

private static int[FT_Pixel_Mode] pixelModeChannelMap;
private static int[FT_Pixel_Mode] pixelModeBPCMap;

static this()
{
    FTSupport ret = loadFreeType();
    error(ret != FTSupport.noLibrary, "Could not find freetype library");
    error(ret != FTSupport.badLibrary, "Failed to load freetype");
    info("Loaded freetype version %s", to!(string)(ret).toStringz());
    error(!FT_Init_FreeType(&ft), "Could not init freetype library");
    pixelModeChannelMap = [
        FT_PIXEL_MODE_NONE: 0u,
        FT_PIXEL_MODE_GRAY: 1u,
        FT_PIXEL_MODE_GRAY2: 1u,
        FT_PIXEL_MODE_GRAY4: 1u,
        FT_PIXEL_MODE_LCD: 3u,
        FT_PIXEL_MODE_LCD_V: 3u,
        FT_PIXEL_MODE_MAX: 4
    ];
    pixelModeBPCMap = [
        FT_PIXEL_MODE_NONE: 0u,
        FT_PIXEL_MODE_GRAY: 1u,
        FT_PIXEL_MODE_GRAY2: 2u,
        FT_PIXEL_MODE_GRAY4: 4u,
        FT_PIXEL_MODE_LCD: 8u,
        FT_PIXEL_MODE_LCD_V: 8u,
        FT_PIXEL_MODE_MAX: 8u
    ];
}

struct Font
{

    import std.typecons;
    private FT_Face face;
    private IFImage[Tuple!(uint,uint,char)] glyphCache;
    private uint currentWidth;
    private uint currentHeight;
    static Font load(string sysPath)
    {
        Font font;
        
        info("Loading font %s", sysPath);
        Logger.LogError(!FT_New_Face(ft, toStringz(sysPath), 0, &font.face),
                "Failed to load font %s", sysPath);
        return font;
    }

    void setPixelSize(uint width, uint height)
    {
        FT_Set_Pixel_Sizes(face, width, height);
        currentWidth = width;
        currentHeight = height;
        //glyphCache.clear();
        
    }

    private IFImage loadChar(char c)
	{
        IFImage result;
        if (FT_Error err = FT_Load_Char(face, cast(uint)c, FT_LOAD_RENDER) != 0)
		{
			Logger.LogError("Could not load glyph %s\nError: %s", c,FT_Error_String(err));
			return result;
		}

	    FT_Bitmap bitmap = face.glyph.bitmap;
		result.w = bitmap.width;
        result.h = bitmap.rows;
        if (bitmap.pixel_mode in pixelModeChannelMap)
        {
            result.c = cast(ubyte) pixelModeChannelMap[bitmap.pixel_mode];
            result.cinfile = cast(ubyte) pixelModeChannelMap[bitmap.pixel_mode];
        }
        else
        {
            result.c = 3;
            result.cinfile = 3;
        }
        if (bitmap.pixel_mode in pixelModeBPCMap)
        {
            result.bpc = cast(ubyte) pixelModeBPCMap[bitmap.pixel_mode];

        }
        else
        {
            result.bpc = 8;
        }
        int arrayLength = result.w * result.h;
        if (result.bpc == 8)
        {
            result.buf8 = cast(ubyte[]) bitmap.buffer[0 .. arrayLength].dup;
        }
        else if (result.bpc == 16)
        {
            result.buf16 = cast(ushort[]) bitmap.buffer[0 .. arrayLength].dup;
        }
        else
		{
            result.buf8 = cast(ubyte[]) bitmap.buffer[0 .. arrayLength].dup;
		}
        return result;
		
	}

    IFImage getChar(char c)
    {
        
        return glyphCache.require(tuple(currentWidth,currentHeight,c),loadChar(c));
    }

}
