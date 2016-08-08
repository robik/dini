/**
 * Implements INI reader.
 *
 * `INIReader` is fairly low-level, configurable reader for reading INI data,
 * which you can use to build your own object-model.
 *
 * High level interface is available in `dini.parser`.
 *
 *
 * Unless you need to change `INIReader` behaviour, you should use one of provided
 * preconfigured readers:
 *
 *  - `StrictINIReader`
 *
 *     Lower compatibility, may be bit faster.
 *
 *
 *  - `UniversalINIReader`
 *
 *     Higher compatibility, may be slighly slower.
 */
module dini.reader;

import std.algorithm  : countUntil, canFind, map;
import std.array 	  : array;
import std.functional : unaryFun;
import std.string 	  : representation, assumeUTF, strip,
	stripLeft, stripRight, split, join, format;
import std.range 	  : ElementType, replace;
import std.uni 		  : isWhite, isSpace;
import std.variant 	  : Algebraic;
import dini.utils     : isBoxer, BoxerType, parseEscapeSequences;


/**
 * Represents type of current token used by INIReader.
 */
enum INIToken
{
    BLANK, 	 ///
    SECTION, ///
    KEY,	 ///
    COMMENT	 ///
}


/**
 * Represents a block definition.
 *
 * Block definitions are used to define new quote and comment sequences
 * to be accepted by INIReader.
 *
 * BlockDefs can be either single line or multiline. To define new single
 * line block `INIBlockDef.mutliline` must be set to `false` AND `closing`
 * must be set to newline string(`"\n"`).
 */
struct INIBlockDef
{
	/**
	 * Opening character sequence
	 */
	string opening;

	/**
	 * Closing character sequence
	 */
	string closing;

	/**
	 * Should newline characters be allowed?
	 */
	bool multiline;
}


/**
 * INIReader behaviour flags.
 *
 * These flags can be used to modify INIReader behaviour.
 */
enum INIFlags : uint
{
    /**
     * Should escape sequences be translated?
     */
	ProcessEscapes 	= 1 << 0,


    /**
     * Section names will be trimmed.
     */
	TrimSections	= 1 << 4,

    /**
     * Key names will be trimmed.
     */
	TrimKeys 		= 1 << 5,

    /**
     * Values will be trimmed.
     */
	TrimValues		= 1 << 6,

    /**
     * Section names, keys and values will be trimmed.
     */
	TrimAll			= TrimSections | TrimKeys | TrimValues
}


/**
 * Defines INI format.
 *
 * This struct defines INI comments and quotes sequences.
 *
 * `INIReader` adds no default quotes or comment definitions,
 * and thus when defining custom format make sure to include default
 * definitions to increase compatibility.
 */
struct INIFormatDescriptor
{
    /**
     * List of comment definitions to support.
     */
    INIBlockDef[] comments;

    /**
     * List of quote definitions to support.
     */
    INIBlockDef[] quotes;
}


/**
 * Strict INI format.
 *
 * This format is used by `MinimalINIReader`.
 *
 * This format defines only `;` as comment character and `"` as only quote.
 * For more universal format consider using `UniversalINIFormat`.
 */
const INIFormatDescriptor StrictINIFormat = INIFormatDescriptor(
    [INIBlockDef(";", "\n", false)],
    [INIBlockDef(`"`, `"`, false)]
);


/**
 * Universal INI format.
 *
 * This format extends `StrictINIFormat` with hash-comments (`#`) and multiline
 * triple-quotes (`"""`).
 */
const INIFormatDescriptor UniversalINIFormat = INIFormatDescriptor(
    [INIBlockDef(";", "\n", false), INIBlockDef("#", "\n", false)],
    [INIBlockDef(`"""`, `"""`, true), INIBlockDef(`"`, `"`, false)]
);


/**
 * Thrown when an parsing error occurred.
 */
class INIException : Exception
{
	this(string msg = null, Throwable next = null) { super(msg, next); }
	this(string msg, string file, size_t line, Throwable next = null) {
		super(msg, file, line, next);
	}
}


/**
 * Represents parsed INI key.
 *
 * Prefer using `YOUR_READER.KeyType` alias.
 */
struct INIReaderKey(ValueType)
{
    /**
     * Key name
     */
    string name;

    /**
     * Key value (may be boxed)
     */
    ValueType value;
}


/**
 * Splits source into tokens.
 *
 * This struct requires token delimeters to be ASCII-characters,
 * Unicode is not supported **only** for token delimeters.
 *
 * Unless you want to modify `INIReader` behaviour prefer using one of available
 * preconfigured variants:
 *
 *  - `StrictINIReader`
 *  - `UniversalINIReader`
 *
 *
 * `INIReader` expects three template arguments:
 *
 *   - `Format`
 *
 *      Instance of `INIFormatDescriptor`, defines quote and comment sequences.
 *
 *
 *   - `Flags`
 *
 *     `INIReaderFlags` (can be OR-ed)
 *
 *
 *   - `Boxer`
 *
 *      Name of a function that takes `(string value, INIReader reader)` and returns a value.
 *      By default all readers just proxy values, doing nothing, but this can be used to e.g.
 *      store token values as JSONValue or other Algebraic-like type.
 *
 *      `INIReader.BoxType` is always return type of boxer function. So if you passed a boxer that
 *      returns `SomeAlgebraic` then `typeof(reader.key.value)` is `SomeAlgebraic`.
 *
 *
 * Params:
 *   Format - `INIFormatDescriptor` to use.
 *   Flags  - Reader behaviour flags.
 *   Boxer  - Function name that can optionally box values.
 *
 *
 * Examples:
 * ---
 * auto reader = UniversalINIReader("key=value\n");
 *
 * while (reader.next) {
 *    writeln(reader.value);
 * }
 * ---
 */
struct INIReader(INIFormatDescriptor Format, ubyte Flags = 0x00, alias Boxer)
    if (isBoxer!Boxer)
{
    /**
     * Reader's format descriptor.
     */
	alias CurrentFormat = Format;

    /**
     * Reader's flags.
     */
	alias CurrentFlags = Flags;

    /**
     * Reader's boxer.
     */
	alias CurrentBoxer = Boxer;

    /**
     * Reader's Box type (boxer return type).
     */
	alias BoxType = BoxerType!Boxer;


    /**
     * Alias for INIReaderKey!(BoxType).
     */
	alias KeyType = INIReaderKey!BoxType;

	/**
	 * Type of `value` property.
	 */
	alias TokenValue = Algebraic!(string, KeyType);


    /**
     * INI source bytes.
     */
    immutable(ubyte)[] source;

    /**
     * INI source offset in bytes.
     */
	size_t sourceOffset;

	/**
	 * Type of current token.
	 */
    INIToken type;

    /**
     * Indicates whenever source has been exhausted.
     */
    bool empty;

    /**
     * Used only with Key tokens.
     *
     * Indicates whenever current value has been quoted.
     * This information can be used by Boxers to skip boxing of quoted values.
     */
	bool isQuoted;

	/**
	 * Current token's value.
	 */
	TokenValue value;


    /**
     * Creates new instance of `INIReader` from `source`.
     *
     * If passed source does not end with newline it is added (and thus allocates).
     * To prevent allocation make sure `source` ends with new line.
     *
     * Params:
     *  source - INI source.
     */
	this(string source)
	{
		// Make source end with newline
		if (source[$-1] != '\n')
			this.source = (source ~ "\n").representation;
		else
			this.source = source.representation;
	}

    /**
     * Returns key token.
     *
     * Use this only if you know current token is KEY.
     */
    KeyType key() @property {
        return value.get!KeyType;
    }

    /**
     * Returns section name.
     *
     * Use this only if you know current token is SECTION.
     */
    string sectionName() @property {
        return value.get!string;
    }

    /**
     * Reads next token.
     *
     * Returns:
     *  True if more tokens are available, false otherwise.
     */
    bool next()
    {
		isQuoted = false;
        skipWhitespaces();

		if (current.length == 0) {
			empty = true;
            return false;
		}

        int pairIndex = -1;
		while(source.length - sourceOffset > 0)
		{
            if (findPair!`comments`(pairIndex)) {
                readComment(pairIndex);
                break;
            }
            else if (current[0] == '[') {
                readSection();
                break;
            }
            else if (isWhite(current[0])) {
                skipWhitespaces();
            }
            else {
				readEntry();
                break;
            }
        }

        return true;
    }

    bool findPair(string fieldName)(out int pairIndex)
    {
		if (source.length - sourceOffset > 0 && sourceOffset > 0 && source[sourceOffset - 1] == '\\') return false;

		alias MemberType = typeof(__traits(getMember, Format, fieldName));
		foreach (size_t i, ElementType!MemberType pairs; __traits(getMember, Format, fieldName)) {
			string opening = pairs.tupleof[0];

            if (source.length - sourceOffset < opening.length)
                continue;

            if (current[0..opening.length] == opening) {
                pairIndex = cast(int)i;
                return true;
            }
        }

        return false;
    }

    void readSection()
	{
        type = INIToken.SECTION;
        auto index = current.countUntil(']');
        if (index == -1)
			throw new INIException("Section not closed");

        value = current[1 .. index].assumeUTF;

		static if (Flags & INIFlags.TrimSections)
			value = value.get!string.strip;

        sourceOffset += index + 1;
    }

    void readComment(int pairIndex)
	{
        type = INIToken.COMMENT;
		INIBlockDef commentDef = Format.comments[pairIndex];
		sourceOffset += commentDef.opening.length;

        auto index = current.countUntil(commentDef.closing);
        if (index == -1)
			throw new INIException("Comment not closed");

		value = current[0.. index].assumeUTF;

		if (commentDef.multiline == false && value.get!string.canFind('\n'))
			throw new INIException("Comment not closed (multiline)");

		sourceOffset += index + commentDef.closing.length;
    }

    void readEntry()
	{
        type = INIToken.KEY;
		KeyType key;

		readKey(key);
		if (current[0] == '=') {
			sourceOffset += 1;
			key.value = readValue();
		}

        value = key;
    }

	void readKey(out KeyType key)
	{
		if (tryReadQuote(key.name)) {
			isQuoted = true;
			return;
		}

		auto newLineOffset = current.countUntil('\n');
		if (newLineOffset > 0) { // read untill newline/some assign sequence
			auto offset = current[0..newLineOffset].countUntil('=');

			if (offset == -1)
				key.name = current[0 .. newLineOffset].assumeUTF;
			else
				key.name = current[0 .. offset].assumeUTF;

			sourceOffset += key.name.length;
			key.name = key.name.stripRight;

			static if (Flags & INIFlags.TrimKeys)
				key.name = key.name.stripLeft;
		}
	}


	BoxType readValue()
	{
        auto firstNonSpaceIndex = current.countUntil!(a => !isSpace(a));
        if (firstNonSpaceIndex > 0)
			sourceOffset += firstNonSpaceIndex;

		string result = "";
		auto indexBeforeQuotes = sourceOffset;

		isQuoted = tryReadQuote(result);
        auto newlineOffset = current.countUntil('\n');
		string remains = current[0..newlineOffset].assumeUTF;

		if (isQuoted && newlineOffset > 0) {
			sourceOffset = indexBeforeQuotes;
			isQuoted = false;
		}

		if (!isQuoted) {
			bool escaped = false;
			int[] newlineOffsets = [];
			auto localOffset = 0;
			for (; source.length - sourceOffset > 0; ++localOffset) {
				if (source[sourceOffset + localOffset] == '\\') {
					escaped = !escaped;
					continue;
				}

				else if(escaped && source[sourceOffset + localOffset] == '\r')
					continue;

				else if(escaped && source[sourceOffset + localOffset] == '\n')
					newlineOffsets ~= localOffset;

				else if (!escaped && source[sourceOffset + localOffset] == '\n')
					break;

				escaped = false;
			}

			result = current[0..localOffset].assumeUTF.split("\n").map!((line) {
				line = line.stripRight;
				if (line[$-1] == '\\') return line[0..$-1].stripLeft;
				return line.stripLeft;
			}).array.join();
			sourceOffset += localOffset;
		}

		static if (Flags & INIFlags.TrimValues)
			if (!isQuoted)
				result = result.strip;

    	static if (Flags & INIFlags.ProcessEscapes)
			result = parseEscapeSequences(result);

        return Boxer(result);
    }

	bool tryReadQuote(out string result)
	{
		int pairIndex;

		if (findPair!`quotes`(pairIndex)) {
			auto quote = Format.quotes[pairIndex];
			sourceOffset += quote.opening.length;

			auto closeIndex = current.countUntil(quote.closing);
			if (closeIndex == -1)
				throw new INIException("Unterminated string literal");

			result = current[0..closeIndex].assumeUTF;
			sourceOffset += result.length + quote.closing.length;

			if (result.canFind('\n') && quote.multiline == false)
				throw new INIException("Unterminated string literal which spans multiple lines (invalid quotes used?)");

			return true;
		}

		return false;
	}

    void skipWhitespaces()
	{
		while (current.length && isWhite(current[0]))
			sourceOffset += 1;
    }

	private immutable(ubyte)[] current() @property {
		return source[sourceOffset..$];
	}
}


/**
 * Universal `INIReader` variant.
 *
 * Use this variant if you want to have more compatible parser.
 *
 * Specifics:
 *   - Uses `UniversalINIFormat`.
 *   - Trims section names, keys and values.
 *   - Processes escapes in values (e.g. `\n`).
 */
alias UniversalINIReader = INIReader!(UniversalINIFormat, INIFlags.TrimAll | INIFlags.ProcessEscapes, (string a) => a);


/**
 * Strict `INIReader` variant.
 *
 * Use this variant if you want to have more strict (and bit faster) parser.
 *
 * Specifics:
 *   - Uses `StrictINIFormat`
 *   - Only Keys are trimmed.
 *   - No escape sequences are resolved.
 */
alias StrictINIReader = INIReader!(StrictINIFormat, INIFlags.TrimKeys, (string a) => a);


unittest {
    auto source = `
; comment

multiline = """
  this is
"""

numeric=-100000
numeric2=09843
[section (name)]
@=bar
`;


	auto reader = UniversalINIReader(source);
	alias Key = reader.KeyType;

	assert(reader.next());
    assert(reader.type == INIToken.COMMENT);
	assert(reader.sectionName == " comment");

	assert(reader.next());
    assert(reader.type == INIToken.KEY);
    assert(reader.key.name == "multiline");
    assert(reader.key.value == "\n  this is\n");

	assert(reader.next());
	assert(reader.type == INIToken.KEY);
	assert(reader.value.get!Key.name == "numeric");
	assert(reader.value.get!Key.value == "-100000");

	assert(reader.next());
	assert(reader.type == INIToken.KEY);
	assert(reader.value.get!Key.name == "numeric2");
	assert(reader.value.get!Key.value == "09843");

	assert(reader.next());
    assert(reader.type == INIToken.SECTION);
	assert(reader.value.get!string == "section (name)");

	assert(reader.next());
	assert(reader.type == INIToken.KEY);
	assert(reader.value.get!Key.name == "@");
	assert(reader.value.get!Key.value == `bar`);

	assert(!reader.next());
}


unittest {
	auto source = `
####### TEST ########

numeric value=15
ThisIsMultilineValue=thisis\
  verylong # comment
"Floating=Value"=1.51

[] # comment works
JustAKey
`;

	auto reader = UniversalINIReader(source);
	alias Key = reader.KeyType;

	assert(reader.next());
	assert(reader.type == INIToken.COMMENT);
	assert(reader.value.get!string == "###### TEST ########");

	assert(reader.next());
	assert(reader.type == INIToken.KEY);
	assert(reader.value.get!Key.name == "numeric value");
	assert(reader.value.get!Key.value == `15`);

	assert(reader.next());
	assert(reader.type == INIToken.KEY);
	assert(reader.value.get!Key.name == "ThisIsMultilineValue");
	assert(reader.value.get!Key.value == `thisisverylong # comment`);

	assert(reader.next());
	assert(reader.type == INIToken.KEY);
	assert(reader.value.get!Key.name == "Floating=Value");
	assert(reader.value.get!Key.value == `1.51`);

	assert(reader.next());
	assert(reader.type == INIToken.SECTION);
	assert(reader.value.get!string == "");

	assert(reader.next());
	assert(reader.type == INIToken.COMMENT);
	assert(reader.value.get!string == " comment works");

	assert(reader.next());
	assert(reader.type == INIToken.KEY);
	assert(reader.value.get!Key.name == "JustAKey");
	assert(reader.value.get!Key.value == null);

	assert(!reader.next());
}

unittest {
	string source = `
	[ Debug ]
sNumString=10Test
QuotedNum="10"
QuotedFloat="10.1"
Num=10
Float=10.1
`;

	auto reader = UniversalINIReader(source);
	alias Key = reader.KeyType;

	assert(reader.next());
	assert(reader.type == INIToken.SECTION);
	assert(reader.value.get!string == "Debug");

	assert(reader.next());
	assert(reader.type == INIToken.KEY);
	assert(reader.value.get!Key.name == "sNumString");
	assert(reader.value.get!Key.value == `10Test`);

	assert(reader.next());
	assert(reader.type == INIToken.KEY);
	assert(reader.value.get!Key.name == "QuotedNum");
	assert(reader.value.get!Key.value == `10`);

	assert(reader.next());
	assert(reader.type == INIToken.KEY);
	assert(reader.value.get!Key.name == "QuotedFloat");
	assert(reader.value.get!Key.value == `10.1`);

	assert(reader.next());
	assert(reader.type == INIToken.KEY);
	assert(reader.value.get!Key.name == "Num");
	assert(reader.value.get!Key.value == "10");

	assert(reader.next());
	assert(reader.type == INIToken.KEY);
	assert(reader.value.get!Key.name == "Float");
	assert(reader.value.get!Key.value == "10.1");

	assert(!reader.next());
}

unittest {
	string source = `
	[ Debug ]
sNumString=10Test
QuotedNum="10"
QuotedFloat="10.1"
Num=10
Float=10.1
`;

	auto reader = StrictINIReader(source);
	alias Key = reader.KeyType;

	assert(reader.next());
	assert(reader.type == INIToken.SECTION);
	assert(reader.value.get!string == " Debug ");

	assert(reader.next());
	assert(reader.type == INIToken.KEY);
	assert(reader.value.get!Key.name == "sNumString");
	assert(reader.value.get!Key.value == `10Test`);

	assert(reader.next());
	assert(reader.type == INIToken.KEY);
	assert(reader.value.get!Key.name == "QuotedNum");
	assert(reader.value.get!Key.value == `10`);

	assert(reader.next());
	assert(reader.type == INIToken.KEY);
	assert(reader.value.get!Key.name == "QuotedFloat");
	assert(reader.value.get!Key.value == `10.1`);

	assert(reader.next());
	assert(reader.type == INIToken.KEY);
	assert(reader.value.get!Key.name == "Num");
	assert(reader.value.get!Key.value == `10`);

	assert(reader.next());
	assert(reader.type == INIToken.KEY);
	assert(reader.value.get!Key.name == "Float");
	assert(reader.value.get!Key.value == `10.1`);

	assert(!reader.next());
}