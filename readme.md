# `dini`

![BuildStatus](https://travis-ci.org/robik/DIni.svg)
[![Version](https://img.shields.io/dub/v/dini.svg)](https://code.dlang.org/packages/dini)
[![Downloads](https://img.shields.io/dub/dt/dini.svg)](https://code.dlang.org/packages/dini)
![Maintained](https://img.shields.io/maintenance/yes/2016.svg)

`dini` is a library written in [D Programming Language](http://www.dlang.org/)
that allows you to read and write INI configuration files with ease.

## Features

 - __Easy to use__
     
     Documentation and examples helps you understand library. It's also very nice to use :).

 - __Well documented__
     
     The code is well documented. If you find something that isn't, be sure to open issue about it.
 
 - __Variable lookups__
     
    You can "paste" defined variables values in values using `%variable%`
 
 - __Section inheriting__   
    
    Sections can inherit values from other sections
    
 - __Configurable__
 
    *Since version 2*
 
    You can define custom quotes, comments and use custom type to store values (*reader only*).
    
    Also, if you want to create custom data from INI, you can use `INIReader` to construct one.


> __NOTE__: Current development version - `2.0.0` is backwards API compatible, if you have any compatibility issues, __please__ report them.


# Quick start

## Installation

__Stable version__

```js
{
    ...
    "dependencies": {
        "dini": "~> 1.0.1"
    }
    ...
}
```

__Latest version__
```js
{
    ...
    "dependencies": {
        "dini": "~> 2.0.0-rc"
    }
    ...
}
```


## Usage

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

You can also set INI variables before parsing:

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
This allows for using `%currentdir%` in configuration file now.

#### Global Inheriting

If you would like to inherit sections that are in another one, you can use  `.` at the beggining to start from global scope:

```ini
[a]
[a.b]

[b]
; Note the dot at beggining
[b.c : .a.b]
```


#### Global lookups

The same goes for variable lookups:

```ini
[a]
[a.b]
var=test

[b]
[b.c]
var=%.a.b.var%
```
