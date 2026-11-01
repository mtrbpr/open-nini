class StoredCookie {
  const StoredCookie({required this.name, required this.value, required this.remove});

  final String name;
  final String value;
  final bool remove;
}

List<String> splitSetCookieHeader(String header) {
  final parts = <String>[];
  final current = StringBuffer();
  for (final segment in header.split(',')) {
    final startsCookie = current.isNotEmpty &&
        !RegExp(r'^\s*\d').hasMatch(segment) &&
        RegExp(r"""^\s*[!#$%&'*+\-.^_`|~0-9A-Za-z]+=\S""").hasMatch(segment);
    if (startsCookie) {
      parts.add(current.toString().trim());
      current.clear();
      current.write(segment.trim());
    } else {
      if (current.isNotEmpty) current.write(',');
      current.write(segment);
    }
  }
  if (current.isNotEmpty) parts.add(current.toString().trim());
  return parts.where((part) => part.isNotEmpty).toList();
}

StoredCookie? parseSetCookie(String setCookie) {
  final pieces = setCookie.split(';');
  final first = pieces.first.trim();
  final eq = first.indexOf('=');
  if (eq <= 0) return null;
  final name = first.substring(0, eq).trim();
  final value = first.substring(eq + 1).trim();
  var remove = value.isEmpty;
  for (final attr in pieces.skip(1)) {
    final piece = attr.trim().toLowerCase();
    if (piece.startsWith('domain=')) {
      final domain = piece.substring('domain='.length).trim();
      if (domain.isNotEmpty && !domain.contains('ninisite.com')) return null;
    }
    if (piece.startsWith('max-age=')) {
      final age = int.tryParse(piece.substring('max-age='.length).trim());
      if (age != null && age <= 0) remove = true;
    }
  }
  return StoredCookie(name: name, value: value, remove: remove);
}

void storeSetCookieHeader(Map<String, String> cookies, String? header) {
  if (header == null || header.isEmpty) return;
  for (final part in splitSetCookieHeader(header)) {
    final cookie = parseSetCookie(part);
    if (cookie == null) continue;
    if (cookie.remove) {
      cookies.remove(cookie.name);
    } else {
      cookies[cookie.name] = cookie.value;
    }
  }
}

String cookieHeader(Map<String, String> cookies) {
  final names = cookies.keys.toList()..sort();
  return names.map((name) => '$name=${cookies[name]}').join('; ');
}
