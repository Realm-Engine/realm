/+ dub.sdl:
    name "initScript"
	libs "curl"
+/
import std.stdio;
import std.getopt;
import std.net.curl;
import std.file;
import std.json;
import std.array;
import std.zip;
import std.string;
import std.algorithm.iteration;
void getFreetype(string [] args)
{

	string root;
	auto helpInformation = getopt(args,"realm-root", &root);
	if(exists(root ~ "/external/freetype"))
	{
		writeln("Freetype found, not downloading");
		return;
	}
	mkdir(root ~ "/external/freetype");
	
	writeln("Freetype release not found, downloading ");
	auto http = HTTP();

	http.addRequestHeader("Accept","application/vnd.github.v3+json");
	string request = "https://api.github.com/repos/realm-engine/freetype-windows-binaries/releases/latest";

	JSONValue response = parseJSON(get(request,http),JSONOptions.doNotEscapeSlashes);
	
	JSONValue zipUrl = response["zipball_url"];

	if(!zipUrl.isNull)
	{

		//download(zipUrl.str(),"./freetype.zip");
		ubyte[] zipFile = get!(AutoProtocol, ubyte)(zipUrl.str);
		auto zip = new ZipArchive(zipFile);
		ArchiveMember[] directories;
		ArchiveMember[] files;
		foreach(ArchiveMember am; zip.directory)
		{
			if(am.expandedSize == 0)
			{
				directories ~= am;
			}
			else
			{
				files ~= am;
			}
		}
		foreach(am; directories ~ files)
		{
			string outName = root ~ "/external/freetype/"~am.name[am.name.indexOf('/') + 1..am.name.length];
			if(am.expandedSize == 0)
			{
				mkdirRecurse(outName);
			}
			else
			{
				zip.expand(am);
				auto data = am.expandedData;
				std.file.write(outName,data);
			}

		}

	}
   

    

}

int main(string[] args)
{

    writefln("Downloading\n");
    

    getFreetype(args);
    
    return 0;
}
