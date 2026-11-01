import 'package:html/dom.dart';

import '../../models.dart';
import '../dates.dart';
import 'html_utils.dart';

const _highlightTitles = [
  'جدیدترین تاپیک های 2 روز گذشته',
  'تاپیک های به روز شده',
  'پربازدیدترین تاپیک های امروز',
  'داغ ترین های تاپیک های 2 روز گذشته',
  'داغ ترین های تاپیک های امروز',
];

DiscussionIndex parseDiscussionIndex(String html) {
  final document = parseDocument(html);
  return DiscussionIndex(
    groups: _groups(document),
    highlights: _highlights(document),
  );
}

List<BoardGroup> _groups(Document document) {
  final shortcuts = <int, _Shortcut>{};
  final shortcutOrder = <int>[];
  for (final link in document.querySelectorAll('a.shortbox-discuss')) {
    final shortcut = _shortcutFrom(link);
    if (shortcut == null || shortcuts.containsKey(shortcut.id)) continue;
    shortcuts[shortcut.id] = shortcut;
    shortcutOrder.add(shortcut.id);
  }

  final tables = <int, BoardGroup>{};
  final tableOrder = <int>[];
  for (final table in document.querySelectorAll('div.category-table')) {
    final boards = table
        .querySelectorAll('a.category--title')
        .map(_boardFromLink)
        .whereType<Board>()
        .toList();
    if (boards.isEmpty) continue;
    final heading = table.querySelector('h2 a');
    if (heading == null) continue;
    final href = heading.attributes['href'];
    if (href == null) continue;
    final path = pathOnly(href);
    final id = categoryIdFromPath(path);
    final name = _categoryName(heading);
    if (id == null || name.isEmpty || tables.containsKey(id)) continue;
    final shortcut = shortcuts[id];
    tables[id] = BoardGroup(
      id: id,
      name: shortcut?.name ?? name,
      path: shortcut?.path ?? path,
      icon: shortcut?.icon,
      boards: boards,
    );
    tableOrder.add(id);
  }

  final ordered = <int>[
    for (final id in shortcutOrder)
      if (tables.containsKey(id)) id,
    for (final id in tableOrder)
      if (!shortcutOrder.contains(id)) id,
  ];
  return [for (final id in ordered) tables[id]!];
}

class _Shortcut {
  const _Shortcut({
    required this.id,
    required this.name,
    required this.path,
    required this.icon,
  });

  final int id;
  final String name;
  final String path;
  final String? icon;
}

_Shortcut? _shortcutFrom(Element link) {
  final href = link.attributes['href'];
  if (href == null) return null;
  final path = pathOnly(href);
  final id = categoryIdFromPath(path);
  final name = collapseSpace(link.querySelector('h2')?.text ?? '');
  if (id == null || name.isEmpty) return null;
  return _Shortcut(id: id, name: name, path: path, icon: _iconClass(link));
}

String? _iconClass(Element link) {
  final icon = link.querySelector('i.fa');
  if (icon == null) return null;
  for (final name in icon.classes) {
    if (name.startsWith('icon')) return name;
  }
  return null;
}

Board? _boardFromLink(Element link) {
  final href = link.attributes['href'];
  if (href == null) return null;
  final path = pathOnly(href);
  final id = idFromPath(path, 'forum');
  final name = collapseSpace(link.text);
  if (id == null || name.isEmpty) return null;

  final details = _nearestDetails(link);
  final latestLink = details?.querySelector('.topic--title a');
  final latestTitle = elementText(latestLink);
  return Board(
    id: id,
    name: name,
    path: path,
    topicCount: firstInt(details?.querySelector('.topic_number')?.text) ?? 0,
    latestTitle: latestTitle,
    latestAuthor: elementText(details?.querySelector('.last-topic-user a')),
    latestWhen: joinWhen(
      elementText(details?.querySelector('.last-topic-date')),
      elementText(details?.querySelector('.last-topic-time')),
    ),
  );
}

Element? _nearestDetails(Element link) {
  Element? current = link.parent;
  while (current != null) {
    final details = current.querySelector('.category--details');
    if (details != null) return details;
    if (current.classes.contains('category--header')) break;
    current = current.parent;
  }
  return link.parent?.querySelector('.category--details');
}

List<TopicSection> _highlights(Document document) {
  final found = <String, TopicSection>{};
  for (final section in document.querySelectorAll('div.newest--topic')) {
    _keepSection(found, section, '.newest--topic__title', _newestTopics);
  }
  for (final section in document.querySelectorAll('div.newest-reply')) {
    _keepSection(found, section, '.newest-reply__title', _updatedTopics);
  }
  for (final section in document.querySelectorAll('div.most-viewed-topic')) {
    _keepSection(found, section, '.most-viewed-topic__title', _viewedTopics);
  }
  return [
    for (final title in _highlightTitles)
      if (found[title] != null) found[title]!,
  ];
}

void _keepSection(
  Map<String, TopicSection> found,
  Element section,
  String titleSelector,
  List<HighlightTopic> Function(Element section) topicsOf,
) {
  final title = collapseSpace(section.querySelector(titleSelector)?.text ?? '');
  if (!_highlightTitles.contains(title) || found.containsKey(title)) return;
  final topics = topicsOf(section);
  if (topics.isEmpty) return;
  found[title] = TopicSection(title: title, topics: topics);
}

List<HighlightTopic> _newestTopics(Element section) {
  return [
    for (final item in section.querySelectorAll('div.item'))
      ?_topicFromLink(item.querySelector('a.subject'), subtitle: _authorTime(item)),
  ];
}

List<HighlightTopic> _viewedTopics(Element section) {
  return [
    for (final item in section.querySelectorAll('.most-viewed-topic__item'))
      ?_topicFromLink(
        item.querySelector('.most-viewed-topic__category a'),
        subtitle: _authorTime(item),
      ),
  ];
}

List<HighlightTopic> _updatedTopics(Element section) {
  final topics = <HighlightTopic>[];
  for (final item in section.querySelectorAll('.newest-reply__item')) {
    Element? titleLink;
    for (final link in item.querySelectorAll('a')) {
      final href = link.attributes['href'] ?? '';
      if (href.contains('postId') || parseTopicLink(href) == null) continue;
      titleLink = link;
      break;
    }
    final topic = _topicFromLink(
      titleLink,
      subtitle: _join([elementText(item.querySelector('.newest-reply__message')), _relativeTime(item)]),
    );
    if (topic != null) topics.add(topic);
  }
  return topics;
}

HighlightTopic? _topicFromLink(Element? link, {String? subtitle}) {
  if (link == null) return null;
  final topic = parseTopicLink(link.attributes['href'] ?? '');
  final title = collapseSpace(link.text);
  if (topic == null || title.isEmpty) return null;
  return HighlightTopic(id: topic.id, title: title, path: topic.path, subtitle: subtitle);
}

String? _authorTime(Element item) => _join([elementText(item.querySelector('a.by-user')), _relativeTime(item)]);

String? _relativeTime(Element item) {
  final row =
      item.querySelector('.newest-reply__reply-count') ?? item.querySelector('.most-viewed-topic__view-count');
  if (row == null) return null;
  for (final span in row.querySelectorAll('span')) {
    if (span.classes.contains('sep')) continue;
    final text = collapseSpace(span.text.replaceAll('\u00a0', ' '));
    if (text.isEmpty || text == '|' || text == 'توسط') continue;
    return text;
  }
  return null;
}

String? _join(List<String?> parts) {
  final values = [for (final part in parts) if (part != null && part.isNotEmpty) part];
  if (values.isEmpty) return null;
  return values.join(' · ');
}

String _categoryName(Element heading) {
  final buffer = StringBuffer();
  for (final node in heading.nodes) {
    if (node is Text) {
      buffer.write(node.text);
    } else if (node is Element && !node.classes.contains('count-item')) {
      buffer.write(node.text);
    }
  }
  return collapseSpace(buffer.toString());
}
