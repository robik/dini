import std.stdio, DIni;

void main()
{
    string iniString = 
"; for 16-bit app support
[foo\\bar]
a=v
[c]
d=e
";    
   
    // Create parser instance
	scope iniParser = new IniParser();
    
    // Enable section nestedness and set delimeter to \
	iniParser.sectionDelimeter = "\\";
    
    // Parse and get result
	auto ini = iniParser.parse(iniString);
	
    // Get sections and its keys
	writeln(ini.getSection("foo").getSection("bar")["a"]);
	writeln(ini.getSection("dada"));
	writeln(ini.getSection("c")["d"]);
}
