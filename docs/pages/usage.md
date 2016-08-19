---
title: Usage
layout: page
permalink: /usage/
order: 4
---

Before we continue, let's have a look at minimal example code:

```D
import std.stdio;
import dini;

void main()
{
    // Our configuration contents
    string contents = `
    [window]
        width = 800
        height = 600
`;

    // Parse configuration from `contents` variable
    Ini config = Ini.ParseString(contents);
    
    // Or if you want to load configuration from file:
    // Ini config = Ini.Parse("path/to/config.ini");
    
    writefln("Window size: %s %s", 
        config["window"]("width"), 
        config["window"]("height")
    );
}
```

First we parse INI data from string using `Ini.ParseString` static function. It returns
parsed data as `Ini` instance, which is a convenience alias for `IniSection`.

Returned object is an root section, which contains every element.
Then we access sub-section `[window]` that contains our keys using `config["window"]`. 
This returns instance of `IniSection`. 

Having our subsection we can access keys with `section("keyname")`. Returned values
are strings and integers/booleans/floats must be parsed manually. 

> **Heads up**: You should be really careful with repetetive parsing of values (such as loop) as it
may hit performance dramatically.
 

### Error handling

In the code above we assumed that our configuration contains what we expected.
If any section or key we accessed would not exist, `IniException` is thrown. 
And uncaught would crash our example app.

You can handle such errors threefold:

  - For keys you can use `getKey(name, defaultValue)`. 
    If requested key does not exist, default value will be returned.
    
    ```D
    writefln("Window size: %s %s", 
        config["window"].getKey("width", "800"), 
        config["window"].getKey("height", "600")
    );
    ```
    
  - You can check for element existence with `hasKey`/`hasSection` and react accordingly.
    
  - You can wrap access in `try {} catch` block and exit gracefully.
    
    ```D
    // hint: bad configuration should be checked 
    // before any operation to improve UX
    try {
        writefln("Window size: %s %s", 
            config["window"]("width"), 
            config["window"]("height")
        );
    }
    catch (IniException e) {
        stderr.writeln("Invalid configuration: ", e.message);
    }
    ```
 
### Object model primer

Following is the list of most important methods in `IniSection`:

`section.root`
: Root section or `this` if none (returns `IniSection`)

`section.name`
: Section name (returns `string`)
     
`section.keys`
: Section keys (returns `string[string]`)
     
`section.sections`
: Sub-sections (returns `IniSection[]`)

`section.hasSection(string name)`  
`section.hasKey(string name)`  
`section.hasParent()`
: Checks whenever specified element exists (returns `bool`)

`section.getSection(string name)`  
`section.getKey(string name[, string defaultVal])`     
: Section or key with specified name if found, `IniException` is thrown otherwise
: Returns `IniSection`/`string`

`section.setKey(string name, string value)`
: Sets key value

     
`section.removeSection(string name)`  
`section.removeKey(string name)`
: Removes specified element if exists, noop otherwise.
     
`section.getParent()`
: Returns section parent or `null` if none (returns `IniSection*`)
    

Few words about how data is kept: Keys are stored in hashmap, not allowing duplicate key entries.
This results in key access being `O(1)`. Subsections are stored in dynamic array, thus
section access is `O(n)`.

### Key references
     
By default, when parsing `dini` will resolve all key references. They look like this:

```INI
[api]
endpoint=http://test
user_url=%endpoint%/users
```

After parsing, `api.user_url` will be resolved to `http://test/users`.
This is cool, however may cause you headaches if you do not want this behaviour.

To disable this features, pass `false` as second argument to `Parse`/`ParseString` functions.
You can resolve references with `section.parseLookups()`

This also allows you to load a configuration file, assign values manually (e.g. `ENV` variables) and
then resolve references:

```D
import std.stdio, std.path;
import dini;

void main()
{
    // Parse configuration
    Ini ini = Ini.Parse("path/to/file", false);

    // Set key value
    ini.setKey("currentdir", getcwd());

    // Now %currentdir% references will be replaced
    ini.parseLoopups();
}
```

### Saving

You can save configuration back to file using `section.save(string filename)`, with some limitations:
 
 - Comments will be lost
 - Indentation will be lost
 - Key order may change
 - Resolved key references are lost (resolved values will be written instead).
 - Inherited sections are lost (inherited sections are written).