final _styleBlock = RegExp(r'<style[^>]*>.*?</style>', dotAll: true);
final _rule = RegExp(r'\.([A-Za-z0-9_-]+)\s*\{([^}]*)\}');
final _classAttribute = RegExp(r'\sclass="([^"]*)"');

/// Copies presentation rules out of a `<style>` block and onto each element.
///
/// Ninisite's default avatars set `fill` and `clip-path` only through CSS
/// classes. The Flutter SVG renderer skips `<style>`, which leaves those
/// drawings with no color.
String inlineSvgClasses(String svg) {
  final style = _styleBlock.firstMatch(svg);
  if (style == null) return svg;
  final rules = <String, Map<String, String>>{};
  for (final match in _rule.allMatches(style.group(0)!)) {
    final properties = <String, String>{};
    for (final declaration in match.group(2)!.split(';')) {
      final splitAt = declaration.indexOf(':');
      if (splitAt <= 0) continue;
      final name = declaration.substring(0, splitAt).trim();
      final value = declaration.substring(splitAt + 1).trim();
      if (name.isEmpty || value.isEmpty) continue;
      properties[name] = value;
    }
    if (properties.isNotEmpty) rules[match.group(1)!] = properties;
  }
  final withoutStyle = svg.replaceRange(style.start, style.end, '');
  return withoutStyle.replaceAllMapped(_classAttribute, (match) {
    final attributes = StringBuffer();
    for (final name in match.group(1)!.split(RegExp(r'\s+'))) {
      final properties = rules[name];
      if (properties == null) continue;
      for (final property in properties.entries) {
        attributes.write(' ${property.key}="${_escapeAttr(property.value)}"');
      }
    }
    return attributes.toString();
  });
}

String _escapeAttr(String value) {
  return value.replaceAll('&', '&amp;').replaceAll('"', '&quot;');
}
