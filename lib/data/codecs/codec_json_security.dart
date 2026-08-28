/// Returns the maximum lexical object/array nesting without interpreting
/// braces inside JSON strings.
int codecJsonLexicalDepth(String source) {
  var inString = false;
  var escaped = false;
  var depth = 0;
  var maximum = 0;
  for (final code in source.codeUnits) {
    if (inString) {
      if (escaped) {
        escaped = false;
      } else if (code == 92) {
        escaped = true;
      } else if (code == 34) {
        inString = false;
      }
      continue;
    }
    if (code == 34) {
      inString = true;
    } else if (code == 123 || code == 91) {
      depth++;
      if (depth > maximum) maximum = depth;
    } else if ((code == 125 || code == 93) && depth > 0) {
      depth--;
    }
  }
  return maximum;
}

/// Counts map entries and list items iteratively so nested collections do not
/// consume the call stack.
int codecJsonCollectionEntries(Object? value) {
  var count = 0;
  final pending = <Object?>[value];
  while (pending.isNotEmpty) {
    final current = pending.removeLast();
    if (current is Map) {
      count += current.length;
      pending.addAll(current.values);
    } else if (current is List) {
      count += current.length;
      pending.addAll(current);
    }
  }
  return count;
}
