module realm.engine.asset;
public
{
	import dimage;
	import imagefmt;
}

private
{
	import std.string;
	import std.stdio;
	import std.file;
	import realm.engine.graphics.core;
	import realm.engine.graphics.material;
}

IFImage readImageBytes(string path)
{
	IFImage img = read_image(path,4);
	long fmtIndix = lastIndexOf(path,'.');
	string fmt = path[fmtIndix+1..path.length];
	switch(fmt)
	{
		case "png":
			img = read_image(path,4);
			break;
		case "jpg":
			img = read_image(path,3);
			break;
		default:
			writeln("Unsupported image format");
			break;
	}
	return img;
}

Image readImage(string path)
{
	File source = File(path);
	Image texture;
	long fmtIndix = lastIndexOf(path,'.');
	string fmt = path[fmtIndix+1..path.length];
	switch(fmt)
	{
		case "png":
			texture = PNG.load(source);
			break;
		case "tga":
			texture = TGA.load(source);
			break;
		default:
			writeln("Unsupported image format");
			break;
	}
	return texture;
}


ShaderProgram loadShaderProgram(Mat)(string path)
{
	static assert(isMaterial(Mat) == true);

	


}
