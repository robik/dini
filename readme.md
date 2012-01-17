# Dini

## What's that

Dini is a library written in [D Programming Language](http://www.d-programming-language.org/)
that allows you to parse INI (or similar) configuration files easily.

## Features

 * __Easy to use__
     
     Documentation and examples helps you understand library. It's also very nice to use :).

 * __Customisable__
     
     You can define your own INI delimeters, comment characters and others.


# Learning Dini
## Simple example

Let's check how it works in real life. In the examples, we'll use following configuration file:

```ini
[db]
driver=MySQL
use=true

[db.main]
hostname = localhost
```

The configuration is defining simple database details.

Now, lets try to parse it, we can do it with using code similar to:

```D
import std.stdio, Dini;

void main()
{
    string file = "
[db]
driver=MySQL
use=true

[db.main]
hostname = localhost
"; 
    scope iniParser = new IniParser();
    auto ini = iniParser.parse(file);
    
    // Do something with ini
}
```

