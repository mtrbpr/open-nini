import 'package:html/dom.dart';

import '../../models.dart';
import '../dates.dart';
import 'html_utils.dart';

BoardPage parseBoardPage(String html, {int page = 1}) {
  final document = parseDocument(html);
  final title = collapseSpace(
    document.querySelector('h1.title a')?.text ?? document.querySelector('h1.title')?.text ?? '',
  );
  final header = document.querySelector('.table-forum__title')?.text ?? '';
  final countMatch = RegExp(r'(\d+)\s*تاپیک').firstMatch(normalizeDigits(header));
  final threads = document
      .querySelectorAll('div.topics div.category--header')
      .map(_threadFromRow)
      .whereType<ThreadSummary>()
      .toList();
  final compose = document.querySelector('#topic-form');
  return BoardPage(
    title: title,
    threadCount: countMatch == null ? null : int.tryParse(countMatch.group(1)!),
    threads: threads,
    page: page,
    lastPage: lastPageOf(document),
    categoryId: int.tryParse(compose?.attributes['data-category-id'] ?? ''),
    forumId: int.tryParse(compose?.attributes['data-forum-id'] ?? ''),
  );
}

ThreadSummary? _threadFromRow(Element row) {
  final link = _titleLink(row);
  final href = link?.attributes['href'];
  if (href == null) return null;
  final path = pathOnly(href);
  final id = idFromPath(path, 'topic');
  final title = elementText(row.querySelector('.topic_subject')) ?? elementText(link);
  if (id == null || title == null) return null;

  final replyNode = row.querySelector('div.hidden-sm-down span.topic_number') ??
      row.querySelector('span.topic_number');
  return ThreadSummary(
    id: id,
    title: title,
    path: path,
    author: elementText(row.querySelector('.last-topic-user a')),
    replyCount: firstInt(replyNode?.text) ?? 0,
    lastReply: elementText(row.querySelector('.last-topic-title a')),
    lastWhen: joinWhen(
      elementText(row.querySelector('.last-topic-date')),
      elementText(row.querySelector('.last-topic-time')),
    ),
    pinned: row.querySelector('i.iconpin') != null,
  );
}

Element? _titleLink(Element row) {
  for (final anchor in row.querySelectorAll('a[href*="/discussion/topic/"]')) {
    final href = anchor.attributes['href'] ?? '';
    if (!href.contains('postId=')) return anchor;
  }
  return null;
}
