module dini.utils;

import std.format : format, formatElement, FormatSpec, FormatException, formattedRead;
import std.traits : arity, isCallable, Parameters, ReturnType;


enum bool isBoxer(alias boxer) = isCallable!boxer
        && arity!boxer == 1
        && is(Parameters!boxer[0] == string);

alias BoxerType(alias boxer) = ReturnType!boxer;


static char[char] escapeSequences;
static this() {
	escapeSequences = [
		'n': '\n', 'r': '\r', 't': '\t', 'b': '\b', '\\': '\\',
		'#': '#', ';': ';', '=': '=', ':': ':', '"': '"', '\'': '\''
	];
}

string parseEscapeSequences(string input)
{
	bool inEscape;
	const(char)[] result = [];
	result.reserve(input.length);

	for(auto i = 0; i < input.length; i++) {
		char c = input[i];

		if (inEscape) {
			if (c in escapeSequences)
				result ~= escapeSequences[c];
			else if (c == 'x') {
				ubyte n;
				if (i + 3 > input.length)
					throw new FormatException("Invalid escape sequence (\\x)");
				string s = input[i+1..i+3];
				if (formattedRead(s, "%x", &n) < 1)
					throw new FormatException("Invalid escape sequence (\\x)");
				result ~= cast(char)n;
				i += 2;
			}
			else {
				throw new FormatException("Invalid escape sequence (\\%s..)".format(c));
			}
		}
		else if (!inEscape && c == '\\') {
			inEscape = true;
			continue;
		}
		else result ~= c;

		inEscape = false;
	}

	return cast(string)result;
}

unittest {
	assert(parseEscapeSequences("abc wef ' n r ;a") == "abc wef ' n r ;a");
	assert(parseEscapeSequences(`\\n \\\\\\\\\\r`) == `\n \\\\\r`);
	assert(parseEscapeSequences(`hello\nworld`) == "hello\nworld");
	assert(parseEscapeSequences(`multi\r\nline \#notacomment`) == "multi\r\nline #notacomment");
	assert(parseEscapeSequences(`welp \x5A\x41\x7a`) == "welp ZAz");
}
