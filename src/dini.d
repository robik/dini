/**
 * This file is part of Dini library
 * 
 * Copyright: Robert Pasiński
 * License: MIT License
 */
module dini;

import std.string    : strip;
import std.algorithm : countUntil;
import std.array     : split, replace;

alias countUntil indexOf;

/**
 * Represents Ini key
 */
struct IniKey
{
    /**
     * Ini key name
     */
    string name;
    
    /**
     * Ini key value
     */
    string value;
    
    
    /**
     * Create new IniKey object
     * 
     * Params:
     *  name    =   Name of the key
     *  value   =   Key value
     */
    public this(string name, string value)
    {
        this.name = name;
        this.value = value;
    }
}

/**
 * Represents IniSection
 */
struct IniSection
{
    protected
    {
        /**
         * Section name
         */
        string _name;
        
        /**
         * Keys defined in section
         */
        IniKey[] _keys;
        
        /**
         * Sections in this section
         */
        IniSection[] _sections;
    }
    
    /**
     * Creates new IniSection
     * 
     * Params:
     *  name = Section name
     */
    public this(string name)
    {
        _name = name;
    }
    
    /**
     * Checks if key with specified name exists
     * 
     * Params:
     *  name    =   Key names
     * 
     * Returns:
     *  True if key exists, false otherwise
     */
    public bool keyExists(string name)
    {
        return (searchKey(_name) != -1);
    }   
    
    /**
     * Adds new section
     * 
     * Params:
     *  section =   Section to add
     */
    public void addSection(IniSection section)
    {
        _sections ~= section;
    }
    
    /**
     * Adds new key
     * 
     * Params:
     *  key =   Key to add
     */
    public void addKey(IniKey key)
    {
        auto pos = searchKey(key.name);
        if(pos == -1)
        {
            _keys ~= key;
        }
        else
        {
            _keys[pos].value = key.value;
        }
    }
    
    /**
     * Returns section with specified name, if it does not exists, exception will be thrown.
     * 
     * Params:
     *  name    =   Section name to get
     * 
     * Throws:
     *  IniException if section does not exists
     * 
     * Returns:
     *  Section
     */
    public ref IniSection getSection(string name, char delim = 0)
    {
        if(delim != 0)
        {
            string[] parts = name.split((&delim)[0..1]);
            IniSection* section = &this;
            
            foreach(part; parts)
            {
                section = &getSectionSafe(part);
            }
            return *section;
        }
        auto pos = searchSection(name, delim);
        
        if(pos == -1)
            throw new IniException("Requested section '" ~name ~"' does not exists");
        
        return _sections[pos]; 
    }
    
    /// ditto
    alias getSection opCall;
    
    /**
     * Returns section with specified name, if section does not exists, it will be created.
     * 
     * Params:
     *  name    =   Section name to get
     * 
     * Returns:
     *  Requested section
     */
    public ref IniSection getSectionSafe(string name, char delim = 0)
    {
        try
        {
            return getSection(name, delim);
        }
        catch(IniException e)
        {
            addSection(IniSection(name));
            return getSection(name);
        }
    }
    
    /**
     * Searches sections array for section with specified name and return its offset, -1 if it does not exists
     * 
     * Params:
     *  name    =   Section name
     * 
     * Returns:
     *  Offset, -1 if section does not exists
     */
    protected int searchSection(string name, char delim = 0)
    {
        if(delim != 0)
        {
            string[] parts = name.split((&delim)[0..1]);
            IniSection* section = &this;
            
            foreach(part; parts)
            {
                section = &getSectionSafe(part);
            }
        }
        else
        {
            foreach(i, section; _sections)
            {
                if(section.name == name)
                {
                    return i;
                } 
            }
        }
        
        return -1;
    }
    
    /**
     * Searches key array for key with specified name.
     * 
     * Params:
     *  name    =   Key name
     * 
     * Returns:
     *  Key offset in array, -1 if it does not exists
     */
    protected int searchKey(string name)
    {
        foreach(i, key; _keys)
        {
            if(key.name == name)
            {
                return i;
            } 
        }
        
        return -1;
    }
    
    /**
     * Returns key with specified name, throws exception if key does not exists
     * 
     * Params:
     *  name    =   Name of the key
     * 
     * Throws:
     *  IniException if key does not exists
     * 
     * Returns:
     *  IniKey
     */
    public IniKey getKey(string name)
    {
        auto pos = searchKey(name);
        
        if(pos == -1)
            throw new IniException("Key '"~name~"' does not exists");
        
        return _keys[pos];    
    }
    
    /// ditto
    alias getKey opIndex;
    
    
    /**
     * Sets key new value
     * 
     * Params:
     *  name    =   Name of the key to change
     *  value   =   New key value
     */
    public void setKey(string name, string value)
    {
        auto pos = searchKey(name);
        
        if(pos > -1)
        {
            _keys[pos].value = value;
        }
        else
        {
            _keys ~= IniKey(name, value);
        }
    }
    
    /**
     * Allows for looping through sections
     */
    public int opApply(int delegate(ref IniSection) dg)
    {
        int res;
        
        foreach(section; _sections)
        {
            res = dg(section);
            
            if(res)
                break;
        }
        
        return res; 
    }
    
    /**
     * Allows for looping through keys
     */
    public int opApply(int delegate(ref string, ref string) dg)
    {
        int res;
        
        foreach(key; _keys)
        {
            res = dg(key.name, key.value);
            
            if(res)
                break;
        }
        
        return res; 
    }
    
    /**
     * Allows for looping through keys
     */
    public int opApply(int delegate(ref IniKey) dg)
    {
        int res;
        
        foreach(key; _keys)
        {
            res = dg(key);
            
            if(res)
                break;
        }
        
        return res; 
    }
    
    /**
     * Returns sections array
     */
    public @property sections()
    {
        return _sections;
    }
    
    /**
     * Returns keys array
     */
    public @property keys()
    {
        return _keys;
    }
    
    
    /**
     * Section name
     * 
     * Returns:
     *  Section name
     */
    public @property name()
    {
        return _name;
    }
    
    public void inherit(IniSection section)
    {
        _keys = section.keys;
    }
}

/// ditto
alias IniSection Ini;



/**
 * IniException
 * 
 * This exception is throwed when requested section/key does not exists
 */
class IniException : Exception
{
    /**
     * Creates new IniException object
     */
    this(string msg, string file = __FILE__, uint line = __LINE__)
    {
        super(msg, file, line);
    }
}

struct IniParseStructure
{
    /// Available characters used to comment, default is ';'
    char[] commentChars = [';'];
    
    /// Delimeter characters used to split name/value, default is '='
    char[] delimChars = ['='];
    
    char[][] sectionChars = [ ['[',']'] ];
    
    /// If empty, inheriting is disabled
    char sectionInheritChar = ':';
    
    /// Prefix and suffix of variable lookup
    char variableLoopupChar = '%';
    
    /// Section delimeter used to nest sections, if it is equals to string.init, section nesting is disabled
    string sectionDelimeter = ".";
}

struct IniPrintStructure
{
    /// Comment character
    char commentChar = ';';
    
    /// Delimeter character
    char delimChar = '=';
    
    /// Section characters
    char[] sectionChars = ['[',']'];
    
    /// Section delimeter used to nest sections, if it is equalts to string.init, section nesting is disabled
    string sectionDelimeter;
}

/**
 * IniParser
 */
class IniParser
{
    protected
    {
        /// Previous character
        char prev;
        
        /// Are we between quotes?
        bool inQuote;
        
        /// Are we in lookup?
        bool inLookup;
        
        /// Lookup start offset
        int lookupStart = -1;
        
        /// Current offset in buf
        int offset;
        
        /// States
        enum State { Key, Value, Section, Comment };
        
        /// Current state
        State state;
        
        /// Key to operate on
        IniKey tmp;
        
        /// Buffer
        string buf;
        
        /// Current section name
        string sectionName;
        
        /// Result
        Ini ini;
        
        /// Pointer to section we are in
        IniSection* section;
        
        /// Section open character used
        int[2] sectionCharUsed;
    }
    
    public IniParseStructure structure;
    alias structure this;
    
    /**
     * Creates new IniParser object
     */
    public this()
    {
        structure = IniParseStructure();
        section = &ini;
    }
    
    /**
     * Creates new IniParser object
     *
     * Params:
     *  iniStructure = Possible ini structure
     */
    public this( IniParseStructure iniStructure)
    {
        structure = iniStructure;
        section = &ini;
    }
    
    /**
     * Checks if specified character is delimeter
     * 
     * Params:
     *  c   =   Character to check
     * 
     * Returns:
     *  True if it is, false otherwise
     */
    protected bool isDelimeter(char c)
    {
        return (delimChars.indexOf(c) != -1 && state == State.Key);
    }
    
    /**
     * Checks if specified character starts comment block
     * 
     * Params:
     *  c   =   Character to check
     * 
     * Returns:
     *  True if it is, false otherwise
     */
    protected bool isComment(char c)
    {
        return (commentChars.indexOf(c) != -1);
    }
    
    /**
     * Checks if specified character starts quote block
     * 
     * Params:
     *  c   =   Character to check
     * 
     * Returns:
     *  True if it is, false otherwise
     */
    protected bool isQuote(char c)
    {
        return (c == '"');
    }
    
    /**
     * Checks if specified character starts section name block
     * 
     * Params:
     *  c   =   Character to check
     * 
     * Returns:
     *  True if it is, false otherwise
     */
    protected bool isSectionOpen(char c)
    {
        int pos;
        foreach(i, chars; sectionChars)
        {
            pos = chars.indexOf(c);
            
            if(pos != -1)
            {
                if( prev == '\n' || prev == ']' || prev == char.init)
                {
                    sectionCharUsed = [i, pos];
                    return true;
                }
            }
        }
        
        return false;
    }
    
    /**
     * Checks if specified character closes section name block
     * 
     * Params:
     *  c   =   Character to check
     * 
     * Returns:
     *  True if it is, false otherwise
     */
    protected bool isSectionClose(char c)
    {
        if(state != State.Section)
            return false;
        
        if(c == sectionChars[sectionCharUsed[0]][sectionCharUsed[1] + 1])
            return true;
        
        return false;    
    }
    
    /**
     * Checks if specified character ends value
     * 
     * Params:
     *  c   =   Character to check
     * 
     * Returns:
     *  True if it is, false otherwise
     */
    protected bool isValueEnd(char c)
    {
        return (c == '\n' && state == State.Value);
    }
    
    /**
     * Checks if specifies character begins or ends variable lookup
     * 
     * Params:
     *  c = Character to check
     *
     * Returns:
     *  True if it is, false otherwise
     */
    protected bool isVariableLookup(char c)
    {
        return (c == variableLoopupChar && inQuote == false && prev != '\\');
    }
    
    /**
     * Resets parser data
     */
    public void reset()
    {
        prev = char.init;
        inQuote = false;
        state = State.Key;
        resetKey(tmp);
        buf = string.init;
        sectionName = string.init;
        ini = Ini.init;
        structure = IniParseStructure.init;
        section = &ini;
    }
    
    /**
     * Resets IniKey contents
     * 
     * Params:
     *  key =   Key to reset
     */
    protected void resetKey(ref IniKey key)
    {
        key.name = "";
        key.value = "";
    }
        
    /**
     * Parses ini string
     * 
     * Params:
     *  source  =   Ini source
     * 
     * Returns:
     *  IniSection
     */
    public Ini parse(string source)
    {
        foreach(i, c; source)
        {
            if(isQuote(c))
            {
                inQuote = !inQuote;
            }
            else if(state == State.Comment)
            {
                if(c == '\n')
                {
                    state = State.Key;
                }
                else
                {
                    continue;
                }
            }
            else if(isComment(c))
            {
                state = State.Comment;
            }
            else if(isVariableLookup(c))
            {
                if(inLookup)
                {
                    string name = buf[lookupStart.. offset];
                    buf.replace("%"~name~"%", section.getKey(name).value);
                }
                else
                {
                    inLookup = true;
                    lookupStart = offset;
                }
            }
            else if(isSectionOpen(c))
            {
                state = State.Section;
                section = &ini;
            }
            else if(isSectionClose(c))
            {
                sectionName = buf;
                string parentName;
                
                if(sectionInheritChar != 0)
                {
                    string[] names = buf.split((&sectionInheritChar)[0..1]);
                    sectionName = names[0].strip();
                    
                    if(names.length > 1)
                    {
                        parentName = names[1].strip();
                    }
                }
                
                if(sectionDelimeter != string.init)
                {
                    auto parts = sectionName.split(sectionDelimeter);
                    
                    
                    foreach(part; parts)
                    {
                        section.addSection(IniSection(part));
                        section = &(section.getSection(part));
                    }
                }
                else
                {
                    section.addSection(IniSection(sectionName));
                    section = &(section.getSection(sectionName));
                }
                
                if(sectionInheritChar != 0 && parentName != "")
                {
                    section.inherit(ini.getSection(parentName));
                }
                
                buf = string.init;
                offset = 0;
                state = State.Key;
            }
            else if(isDelimeter(c))
            {
                tmp.name = buf;
                buf = string.init;
                offset = 0;
                state = State.Value;
            }
            else if(isValueEnd(c))
            {
                tmp.value = buf;
                buf = string.init;
                state = State.Key;
                
                section.addKey(tmp);
                resetKey(tmp);
                offset = 0;
            }
            else
            {
                addStripedChar(c);
            }
            
            prev = c;
        }
        
        tmp.value = buf;        
        section.addKey(tmp);
        
        return ini;
    }
    
    /**
     * Adds character to buffer. If character is white space
     * 
     * Params:
     *  c   =   Character to add to buffer
     */
    protected void addStripedChar(char c)
    {
        if(inQuote)
        {
            buf ~= c;
        }
        else
        {
            if( strip((&c)[0..1]).length != 0 )
            {
                buf ~= c;
            }
        }
        
        offset++;
    }
}

debug
{
    
    import std.stdio;
    void main()
    {
         string c = "[def]
name1=value1
name2=value2

[foo : def]
name1=%name2%";
        auto iniParser = new IniParser();
        auto ini = iniParser.parse(c);
        writeln(ini.getSection("foo"));
    }
}