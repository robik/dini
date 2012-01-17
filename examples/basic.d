import std.stdio : writeln;
import std.file : readText;
import Dini;

void main()
{
    // Create parser instance
	scope iniParser = new IniParser();
    
    // Enable section nestedness and set delimeter to .
	iniParser.sectionDelimeter = ".";
    
    // Parse and get result
	auto ini = iniParser.parse(readText("example.conf"));
	
	// Do something with ini here
}
