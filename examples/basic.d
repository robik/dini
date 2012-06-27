import std.stdio : writeln;
import dini;

void main()
{
    // Parse and get result
    auto ini = Ini.Parse("example.conf");
    
    // Do something with ini here
    // ini[str] is alias for ini.getSection(str)
    writeln(ini["db"].getKey("driver"));
}
