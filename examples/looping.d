import std.stdio : writeln;
import std.file : readText;
import DIni;

void main()
{
    // Create parser instance
    scope iniParser = new IniParser();
    
    // Enable section nestedness and set delimeter to 
    iniParser.sectionDelimeter = ".";
    
    // Parse and get result
    auto ini = iniParser.parse(readText("example.conf"));
    
    foreach(IniSection section; ini)
    {
        writefln("\n-- Section: %s", section.name);
        
        foreach(IniKey key; section)
            writefln("%s: %s", key.name, key.value);
    }
}
