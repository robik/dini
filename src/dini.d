/**
 * This file is part of Dini library
 * 
 * Copyright: Robert Pasiński
 * License: Boost License
 */
module dini;

import std.stdio : File;
import std.string : strip, splitLines;
import std.traits : isSomeString;
import std.range : ElementType;
import std.array  : split, replaceInPlace, join;
import std.algorithm : min, max, countUntil;
import std.conv   : to;

import std.stdio;


/**
 * Represents ini section
 *
 * Example:
 * ---
 * Ini ini = Ini.Parse("path/to/your.conf");
 * string value = ini.getKey("a");
 * ---
 */
struct IniSection
{
    /// Section name
    protected string         _name = "root";
    
    /// Parent
    /// Null if none
    protected IniSection*    _parent;
    
    /// Childs
    protected IniSection[]   _sections;
    
    /// Keys
    protected string[string] _keys;
    
    
    
    /**
     * Creates new IniSection instance
     *
     * Params:
     *  name = Section name
     */
    public this(string name)
    {
        _name = name;
        _parent = null;
    }
    
    
    /**
     * Creates new IniSection instance
     *
     * Params:
     *  name = Section name
     *  parent = Section parent
     */
    public this(string name, IniSection* parent)
    {
        _name = name;
        _parent = parent;
    }
    
    /**
     * Sets section key
     *
     * Params:
     *  name = Key name
     *  value = Value to set
     */
    public void setKey(string name, string value)
    {
        _keys[name] = value;
    }
    
    /**
     * Checks if specified key exists
     *
     * Params:
     *  name = Key name
     *
     * Returns:
     *  True if exists, false otherwise 
     */
    public bool hasKey(string name) @safe nothrow @nogc
    {
        return (name in _keys) !is null;
    }
    
    /**
     * Gets key value
     *
     * Params:
     *  name = Key name
     *
     * Returns:
     *  Key value
     *
     * Throws:
     *  IniException if key does not exists
     */
    public string getKey(string name)
    {
        if(!hasKey(name)) {
            throw new IniException("Key '"~name~"' does not exists");
        }
        
        return _keys[name];
    }
    
    
    /// ditto
    alias getKey opCall;
    
    /**
     * Gets key value or defaultValue if key does not exist
     *
     * Params:
     *  name = Key name
     *  defaultValue = Default value
     *
     * Returns:
     *  Key value or defaultValue
     *
     */
    public string getKey(string name, string defaultValue) @safe nothrow
    {
        return hasKey(name) ? _keys[name] : defaultValue;
    }
    
    /**
     * Removes key
     *
     * Params:
     *  name = Key name
     */
    public void removeKey(string name)
    {
        _keys.remove(name);
    }
    
    /**
     * Adds section
     *
     * Params:
     *  section = Section to add
     */
    public void addSection(ref IniSection section)
    {
        _sections ~= section;
    }
    
    /**
     * Checks if specified section exists
     *
     * Params:
     *  name = Section name
     *
     * Returns:
     *  True if exists, false otherwise 
     */
    public bool hasSection(string name)
    {
        foreach(ref section; _sections)
        {
            if(section.name() == name)
                return true;
        }
        
        return false;
    }
    
    /**
     * Returns reference to section
     *
     * Params:
     *  Section name
     *
     * Returns:
     *  Section with specified name
     */
    public ref IniSection getSection(string name)
    {
        foreach(ref section; _sections)
        {
            if(section.name() == name)
                return section;
        }
        
        throw new IniException("Section '"~name~"' does not exists");
    }
    
    
    /// ditto
    public alias getSection opIndex;
    
    /**
     * Removes section
     *
     * Params:
     *  name = Section name
     */
    public void removeSection(string name)
    {
        IniSection[] childs;
        
        foreach(section; _sections)
        {
            if(section.name != name)
                childs ~= section;
        }
        
        _sections = childs;
    }
    
    /**
     * Section name
     *
     * Returns:
     *  Section name
     */
    public string name() @property
    {
        return _name;
    }
    
    /**
     * Array of keys
     *
     * Returns:
     *  Associative array of keys
     */
    public string[string] keys() @property
    {
        return _keys;
    }
    
    /**
     * Array of sections
     *
     * Returns:
     *  Array of sections
     */
    public IniSection[] sections() @property
    {
        return _sections;
    }
    
    /**
     * Root section
     */
    public IniSection root() @property
    {
        IniSection s = this;
        
        while(s.getParent() != null)
            s = *(s.getParent());
        
        return s;
    }
    
    /**
     * Section parent
     *
     * Returns:
     *  Pointer to parent, or null if parent does not exists
     */
    public IniSection* getParent()
    {
        return _parent;
    }
    
    /**
     * Checks if current section has parent
     *
     * Returns:
     *  True if section has parent, false otherwise
     */
    public bool hasParent()
    {
        return _parent != null;
    }
    
    /**
     * Moves current section to another one
     *
     * Params:
     *  New parent
     */
    public void setParent(ref IniSection parent)
    {
        _parent.removeSection(this.name);
        _parent = &parent;
        parent.addSection(this);
    }
    
    
    /**
     * Parses filename
     *
     * Params:
     *  filename = Configuration filename
     *  doLookups = Should variable lookups be resolved after parsing? 
     */
    public void parse(string filename, bool doLookups = true)
    {
        auto file = new File(filename);
        scope(exit) file.close;

        parse(file, doLookups);
    }

    public void parse(File* file, bool doLookups = true)
    {
        IniSection* section = &this;

        import std.range : enumerate;
        foreach(i, char[] line; file.byLine.enumerate(1))
        {
            parse(line, i, section);
        }
        
        if(doLookups == true)
            parseLookups();
    }

    public void parseString(string data, bool doLookups = true) 
    {
        IniSection* section = &this;

        foreach(i, line; data.splitLines)
            parse(line, i, section);

        if(doLookups == true)
            parseLookups();
    }

    private void parse(const(char)[] line, size_t lineCount, ref IniSection* section)
    {
        line = strip(line);

        // Empty line
        if(line.length < 1) return;

        // Comment line
        if(line[0] == ';')  return;
        if(line[0] == '#')  return;

        // Section header
        if(line.length >= 3 && line[0] == '[' && line[$-1] == ']')
        {
            section = &this;
            const(char)[] name = line[1..$-1];
            string parent;

            ptrdiff_t pos = name.countUntil(":");
            if(pos > -1)
            {
                parent = name[pos+1..$].strip().idup;
                name = name[0..pos].strip();
            }

            if(name.countUntil(".") > -1)
            {
                auto names = name.split(".");
                foreach(part; names)
                {
                    IniSection sect;

                    if(section.hasSection(part.idup)) {
                        sect = section.getSection(part.idup);
                    } else {
                        sect = IniSection(part.idup, section);
                        section.addSection(sect);
                    }

                    section = (&section.getSection(part.idup));
                }
            }
            else
            {
                IniSection sect;

                if(section.hasSection(name.idup)) {
                    sect = section.getSection(name.idup);
                } else {
                    sect = IniSection(name.idup, section);
                    section.addSection(sect);
                }

                section = (&this.getSection(name.idup));
            }

            if(parent.length > 1)
            {
                if(parent[0] == '.')
                    section.inherit(this.getSectionEx(parent[1..$]));
                else 
                    section.inherit(section.getParent().getSectionEx(parent));
            }
            return;
        }

        // Assignement
        auto parts = split(line, "=", 2);
        if(parts.length > 1)
        {
            auto val = parts[1].strip();
            if(val.length > 2 && val[0] == '"' && val[$-1] == '"') val = val[1..$-1];
            section.setKey(parts[0].strip().idup, val.idup);
            return;
        }

        throw new IniException("Syntax error at line "~to!string(lineCount));
    }
    
    /**
     * Parses lookups
     */
    public void parseLookups()
    {
        foreach(name, ref value; _keys)
        {
            ptrdiff_t start = -1;
            char[] buf;
            
            foreach(i, c; value)
            {
                if(c == '%')
                {
                    if(start != -1)
                    {
                        IniSection sect;
                        string newValue;
                        char[][] parts;
                        
                        if(buf[0] == '.')
                        {
                            parts = buf[1..$].split(".");
                            sect = this.root;
                        }
                        else
                        {
                            parts = buf.split(".");
                            sect = this;
                        }
                        
                        newValue = sect.getSectionEx(parts[0..$-1].join(".").idup)
                            .getKey(parts[$-1].idup);
                        
                        value.replaceInPlace(start, i+1, newValue);
                        start = -1;
                        buf = [];
                    }
                    else {
                        start = i;
                    }
                }
                else if(start != -1) {
                    buf ~= c;
                }
            }
        }
        
        foreach(child; _sections)
        {
            child.parseLookups();
        }
    }
    
    /**
     * Returns section by name in inheriting(names connected by dot)
     *
     * Params:
     *  name = Section name
     *
     * Returns:
     *  Section
     */
    public IniSection getSectionEx(string name)
    {
        IniSection* root = &this;
        auto parts = name.split(".");
        
        foreach(part; parts)
        {
            root = (&root.getSection(part));
        }
        
        return *root;
    }
    
    /**
     * Inherits keys from section
     *
     * Params:
     *  Section to inherit
     */
    public void inherit(IniSection sect)
    {
        this._keys = sect.keys().dup;
    }
    
    /**
     * Splits string by delimeter with limit
     *
     * Params:
     *  txt     =   Text to split
     *  delim   =   Delimeter
     *  limit   =   Limit of splits 
     *
     * Returns:
     *  Splitted string
     */
    protected T[] split(T, S)(T txt, S delim, int limit)
    if(isSomeString!(T) && isSomeString!(S))
    {
        limit -= 1;
        T[] parts;
        ptrdiff_t last, len = delim.length, cnt;
        
        for(int i = 0; i <= txt.length; i++)
        {
            if(cnt >= limit)
                break;
            
            if(txt[i .. min(i + len, txt.length)] == delim)
            {
                parts ~= txt[last .. i];
                last = min(i + 1, txt.length);
                cnt++;
            }
        }
        
        parts ~= txt[last .. txt.length];       
        
        return parts;
    }

    public void save(string filename)
    {
        import std.file;

        if (exists(filename))
        {
            remove(filename);
        }

        File file = File(filename, "w");

        foreach (section; _sections)
        {
            file.writeln("[" ~ section.name() ~ "]");

            string[string] propertiesInSection = section.keys();
            foreach (key; propertiesInSection.keys) {
                file.writeln(key ~ " = " ~ propertiesInSection[key]);
            }

            file.writeln();
        }

        file.close();
    }
    
    /**
     * Parses Ini file
     *
     * Params:
     *  filename = Path to ini file
     *
     * Returns:
     *  IniSection root
     */
    static Ini Parse(string filename)
    {
        Ini i;
        i.parse(filename);
        return i;
    }

    static Ini ParseString(string data)
    {
        Ini i;
        i.parseString(data);
        return i;
    }
} unittest {
	auto data = q"EOF
[def]
name1=value1
name2=value2

[foo : def]
name1=Name1 from foo. Lookup for def.name2: %name2%
EOF";

    // Parse file
    auto ini = Ini.ParseString(data);

    assert(ini["foo"].getKey("name1")
	  == "Name1 from foo. Lookup for def.name2: value2");
}

unittest {
	auto data = q"EOF
[section]
name=%value%
EOF";

	// Create ini struct instance
	Ini ini;
	Ini iniSec = IniSection("section");
	ini.addSection(iniSec);

	// Set key value
	ini["section"].setKey("value", "verify");

	// Now, you can use value in ini file
	ini.parseString(data);

	assert(ini["section"].getKey("name") == "verify");
}

/// ditto
alias IniSection Ini;

///
class IniException : Exception
{
    this(string msg, string file = __FILE__, size_t line = __LINE__, Throwable next = null)
    {
        super(msg, file, line, next);
    }
}
