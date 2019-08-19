local helpers = import 'helpers.jsonnet';

//helpers.capitalize("foo");
//std.length("foo")
local word = "foo";
local chars = std.stringChars(word);
std.asciiUpper(chars[0]) + std.foldl( function(a,b) a + b, chars[1:std.length(chars)], "")