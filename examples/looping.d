import std.stdio : writefln;
import dini;

void main()
{   
    // Parse and get result
    auto ini = Ini.Parse("example.conf");
    
    // Loop root section
    foreach(IniSection section; ini.sections)
    {
        writefln("\n-- Section: %s", section.name);
        
        foreach(key, value; section.keys)
            writefln("%s: %s", key, value);
    }
}
