import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;

import '../dates.dart';
import '../../models.dart';

Document parseDocument(String html) => html_parser.parse(html);

const _digitMap = {
  '۰': '0',
  '۱': '1',
  '۲': '2',
  '۳': '3',
  '۴': '4',
  '۵': '5',
  '۶': '6',
  '۷': '7',
  '۸': '8',
  '۹': '9',
  '٠': '0',
  '١': '1',
  '٢': '2',
  '٣': '3',
  '٤': '4',
  '٥': '5',
  '٦': '6',
  '٧': '7',
  '٨': '8',
  '٩': '9',
};

String normalizeDigits(String input) {
  final buffer = StringBuffer();
  for (final rune in input.runes) {
    final char = String.fromCharCode(rune);
    buffer.write(_digitMap[char] ?? char);
  }
  return buffer.toString();
}

int? firstInt(String? input) {
  if (input == null) return null;
  final match = RegExp(r'\d+').firstMatch(normalizeDigits(input));
  if (match == null) return null;
  return int.tryParse(match.group(0)!);
}

String collapseSpace(String input) => input.replaceAll(RegExp(r'\s+'), ' ').trim();

int? idFromPath(String path, String kind) {
  final match = RegExp('/discussion/$kind/(\\d+)').firstMatch(path);
  if (match == null) return null;
  return int.tryParse(match.group(1)!);
}

int? categoryIdFromPath(String path) {
  final match = RegExp(r'^/discussion/(\d+)(?:/|$)').firstMatch(path);
  if (match == null) return null;
  return int.tryParse(match.group(1)!);
}

String pathOnly(String href) {
  final uri = href.startsWith('http://') || href.startsWith('https://')
      ? Uri.parse(href)
      : Uri.parse('https://www.ninisite.com').resolve(href);
  return uri.path;
}

String absoluteUrl(String href) {
  if (href.startsWith('//')) return 'https:$href';
  final uri = Uri.tryParse(href);
  if (uri == null) return href;
  if (uri.hasScheme) return href;
  return Uri.parse('https://www.ninisite.com').resolve(href).toString();
}

TopicLink? parseTopicLink(String href) {
  final uri = href.startsWith('http://') || href.startsWith('https://')
      ? Uri.tryParse(href)
      : Uri.parse('https://www.ninisite.com').resolve(href);
  if (uri == null) return null;
  final host = uri.host;
  if (host.isNotEmpty && host != 'ninisite.com' && !host.endsWith('.ninisite.com')) {
    return null;
  }
  final id = idFromPath(uri.path, 'topic');
  if (id == null) return null;
  return TopicLink(id: id, path: uri.path);
}

int lastPageOf(Document document) {
  final pagination = document.querySelector('ul.pagination');
  if (pagination == null) return 1;
  var maxPage = 1;
  for (final link in pagination.querySelectorAll('a')) {
    final fromHref = _pageFromHref(link.attributes['href']);
    if (fromHref != null && fromHref > maxPage) maxPage = fromHref;
    final fromText = int.tryParse(normalizeDigits(link.text).trim());
    if (fromText != null && fromText > maxPage) maxPage = fromText;
  }
  return maxPage;
}

int? _pageFromHref(String? href) {
  if (href == null) return null;
  final match = RegExp(r'[?&]page=(\d+)').firstMatch(href);
  if (match == null) return null;
  return int.tryParse(match.group(1)!);
}

bool isAd(Element element) => element.classes.contains('forum-native-ad');

String? elementText(Element? element) {
  if (element == null) return null;
  final text = collapseSpace(element.text);
  return text.isEmpty ? null : text;
}

String sanitizePostHtml(Element? root) {
  if (root == null) return '';
  final buffer = StringBuffer();
  for (final node in root.nodes) {
    _writeNode(node, buffer);
  }
  return _tidy(buffer.toString());
}

String _tidy(String html) {
  return html.replaceFirst(RegExp(r'^(?:\s|<p>\s*</p>|<p>\s*<br\s*/?>\s*</p>|<br\s*/?>)+'), '').trim();
}

void _writeNode(Node node, StringBuffer buffer) {
  if (node is Text) {
    buffer.write(_escapeText(node.text));
    return;
  }
  if (node is! Element) return;
  final tag = node.localName?.toLowerCase();
  switch (tag) {
    case 'script':
    case 'style':
    case 'iframe':
    case 'noscript':
      return;
    case 'br':
      buffer.write('<br>');
    case 'p':
    case 'blockquote':
    case 'ul':
    case 'ol':
    case 'li':
      buffer
        ..write('<$tag>')
        ..write(_inner(node))
        ..write('</$tag>');
    case 'strong':
    case 'b':
      buffer
        ..write('<strong>')
        ..write(_inner(node))
        ..write('</strong>');
    case 'em':
    case 'i':
      final classes = node.attributes['class'] ?? '';
      if (classes.contains('fa') || classes.contains('icon')) return;
      buffer
        ..write('<em>')
        ..write(_inner(node))
        ..write('</em>');
    case 'a':
      final href = node.attributes['href'];
      if (href == null || href.isEmpty || href == '#' || href.startsWith('javascript:')) {
        buffer.write(_inner(node));
        return;
      }
      buffer
        ..write('<a href="${_escapeAttr(absoluteUrl(href))}">')
        ..write(_inner(node))
        ..write('</a>');
    case 'img':
      final src = imageSource(node);
      if (src != null) buffer.write('<img src="${_escapeAttr(src)}">');
    default:
      buffer.write(_inner(node));
  }
}

String _inner(Element node) {
  final buffer = StringBuffer();
  for (final child in node.nodes) {
    _writeNode(child, buffer);
  }
  return buffer.toString();
}

String? imageSource(Element img) {
  final original = img.attributes['data-original']?.trim();
  final src = img.attributes['src']?.trim();
  final pick = _preferredImage(original) ?? _preferredImage(src);
  if (pick == null) return null;
  return absoluteUrl(pick);
}

String? _preferredImage(String? value) {
  if (value == null || value.isEmpty || value.contains('blank-loading')) return null;
  return value;
}

String _escapeText(String input) {
  return input
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');
}

String _escapeAttr(String input) => _escapeText(input).replaceAll('"', '&quot;');

DateTime? publishedAt(Element article) {
  final meta = article.querySelector('meta[itemprop="datepublished"]');
  return parseNiniDate(meta?.attributes['content']);
}
