# Dini

## What's that

Dini is a library written in [D Programming Language](http://www.dlang.org/)
that allows you to parse INI configuration files easily.

## Features

 - __Easy to use__
     
     Documentation and examples helps you understand library. It's also very nice to use :).

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
import dini;

void main()
{
    // Parse file
    auto ini = Ini.Parse("path/to/file.conf");
    
    // Print foo.name1 value
    writeln(ini["foo"].getKey("name1"));
}
```

You can also set INI variables, before parsing:

```D
import std.stdio, std.path;
import dini;

void main()
{
    // Create ini struct instance
    Ini ini;
    
    // Set key value
    ini.setKey("currentdir", getcwd());
    
    // Now, you can use currentdir in ini file
    ini.parse();
    
    // Print foo.name1 value
    writeln(ini["foo"].getKey("currentdir"));
}
```


### Global Inheriting

If you would like to inherit sections that are in another one, you can use  `.` at the beggining:

```ini
[a]
[a.b]

[b]
; Note the dot at beggining
[b.c : .a.b]
```


### Global lookups

The same goes for variable lookups:

```ini
[a]
[a.b]
var=test

[b]
[b.c]
var=%.a.b.var%
```
