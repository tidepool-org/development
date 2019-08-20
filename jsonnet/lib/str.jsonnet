{
  isUpper(c):: (
    local cp = std.codepoint(c);
    cp >= 97 && cp < 123
  ),

  capitalize(word):: (
    assert std.isString(word) : 'can only capitalize string';
    assert std.length(word) > 0 : 'cannot capitalize empty string';
    local chars = std.stringChars(word);
    std.asciiUpper(chars[0]) + std.foldl(function(a, b) a + b, chars[1:std.length(chars)], '')
  ),

  kebabCase(camelCaseWord):: (
    local merge(a, b) = {
      local isUpper = $.isUpper(b),
      word: (if isUpper && !a.wasUpper then '%s-%s' else '%s%s') % [a.word, std.asciiLower(b)],
      wasUpper: isUpper,
    };
    std.foldl(merge, std.stringChars(camelCaseWord), { word: '', wasUpper: true }).word
  ),

  camelCase(kebabCaseWord, initialUpper=false):: (
    local merge(a, b) = {
      local isHyphen = (b == '-'),
      word: if isHyphen then a.word else a.word + (if a.toUpper then std.asciiUpper(b) else b),
      toUpper: isHyphen,
    };
    std.foldl(merge, std.stringChars(kebabCaseWord), { word: '', toUpper: initialUpper }).word
  ),

  pascalCase(kebabCaseWord):: $.camelCase(kebabCaseWord, true),
}
