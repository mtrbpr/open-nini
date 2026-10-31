import 'package:html/dom.dart';

import '../../models.dart';
import '../dates.dart';
import 'html_utils.dart';

List<BoardGroup> parseDiscussionIndex(String html) {
  final document = parseDocument(html);
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
