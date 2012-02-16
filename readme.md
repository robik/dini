# Dini

## What's that

Dini is a library written in [D Programming Language](http://www.d-programming-language.org/)
that allows you to parse INI (or similar) configuration files easily.

## Features

 - __Easy to use__
     
     Documentation and examples helps you understand library. It's also very nice to use :).

 - __Customisable__
     
     You can define your own INI delimeters, comment characters and others.
    
 - __Well documented__
     
     The code is well documented, allowing you to understand it easier.
 
 - __Variable lookups__
     
    You can "paste" defined variables values in values using `%variable%`
 
 - __Section inheriting__   
    
    Sections can inherit values from other sections


# Learning Dini
## Simple example

Let's check how it works in real life. In the examples, we'll use following configuration file:

```ini
[def]
name1=value1
name2=value2

[foo : def]
name1=Name1 from foo. Lookup for def.name2: %name2%
```


Now, lets try to parse it, we can do it with using code similar to:

```D
import std.stdio;
void main()
{
     // Hard code the contents
     string c = "[def]
name1=value1
name2=value2

[foo : def]
name1=Name1 from foo. Lookup for def.name2: %name2%";

    // create parser instance
    auto iniParser = new IniParser();
    
    // parse
    auto ini = iniParser.parse(c);
    
    // write foo.name1 value
    writeln(ini.getSection("foo")["name1"].value);
}
```

