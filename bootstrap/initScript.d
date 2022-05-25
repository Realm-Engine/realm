/+ dub.sdl:
    name "initScript"

+/
import std.stdio;
import std.getopt;
import std.net.curl;
import std.file;
import std.json;
import std.array;

void getFreetype(string [] args)
{
    if(!exists("../external/freetype-release"))
	{
		
		string freetypeVersion;
		auto helpInformation = getopt(args,"ft-version",&freetypeVersion);
		writeln("Freetype release not found, downloading version ", freetypeVersion);
		auto http = HTTP();

		http.addRequestHeader("Accept","application/vnd.github.v3+json");
		string request = "https://api.github.com/repos/ubawurinna/freetype-windows-binaries/releases/tags/v" ~ freetypeVersion;

		JSONValue response = parseJSON(get(request,http),JSONOptions.doNotEscapeSlashes);
		writeln(response["zipball_url"].str());
		JSONValue zipUrl = response["zipball_url"];

		if(!zipUrl.isNull)
		{
			download(zipUrl.str(),"./freetype-release.zip");
		}
		else
		{
			writeln("Could not download freetype");
		}
	}

    

}

int main(string[] args)
{

    writefln("Downloading\n");
    

    getFreetype(args);
    download("https://httpbin.org/get", "./downloaded-http-file");
    return 0;
}
