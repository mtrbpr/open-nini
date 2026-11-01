import 'package:html/dom.dart';

import '../../account_models.dart';
import 'html_utils.dart';

final _guid = RegExp(
  r'[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}',
);

bool friendsOnlyFailure(String? message) => message != null && message.contains('دوستان خود');

String? userGuid(String? path) {
  if (path == null || path.isEmpty) return null;
  return _guid.firstMatch(path)?.group(0);
}

String messageSubject(String message) {
  final line = message.trim().split(RegExp(r'\r?\n')).first.trim();
  final plain = line.replaceAll(RegExp(r'\s+'), ' ');
  if (plain.isEmpty) return 'گفتگو';
  if (plain.length <= 100) return plain;
  return plain.substring(0, 100);
}

List<InboxPerson> groupConversations(List<AccountRecord> received, List<AccountRecord> sent) {
  final grouped = <String, _Bucket>{};
  void take(AccountRecord record, int rank, {required bool incoming}) {
    final name = (record.peer ?? record.title).trim();
    if (name.isEmpty) return;
    final key = '$name\n${record.imageUrl ?? ''}';
    final bucket = grouped.putIfAbsent(key, () => _Bucket(name, record.imageUrl));
    final path = record.path;
    if (path != null && path.isNotEmpty && !bucket.threads.contains(path)) bucket.threads.add(path);
    if (incoming && record.unread) bucket.unread = true;
    if (bucket.rank == null || rank < bucket.rank!) {
      bucket.rank = rank;
      bucket.subject = record.title;
      bucket.when = _when(record);
      bucket.replyConversationId = record.id;
    }
  }

  for (var index = 0; index < received.length; index++) {
    take(received[index], index, incoming: true);
  }
  for (var index = 0; index < sent.length; index++) {
    take(sent[index], index, incoming: false);
  }
  final people = grouped.values.toList()..sort((a, b) => (a.rank ?? 0).compareTo(b.rank ?? 0));
  return [
    for (final bucket in people)
      InboxPerson(
        name: bucket.name,
        avatarUrl: bucket.avatarUrl,
        subject: bucket.subject,
        when: bucket.when,
        unread: bucket.unread,
        replyConversationId: bucket.replyConversationId,
        threads: bucket.threads,
      ),
  ];
}

String? _when(AccountRecord record) {
  final subtitle = record.subtitle;
  final peer = record.peer;
  if (subtitle == null || subtitle.isEmpty) return null;
  if (peer != null && subtitle.startsWith(peer)) {
    final rest = subtitle.substring(peer.length).replaceFirst(RegExp(r'^\s*·\s*'), '').trim();
    return rest.isEmpty ? null : rest;
  }
  return subtitle;
}

class _Bucket {
  _Bucket(this.name, this.avatarUrl);

  final String name;
  final String? avatarUrl;
  String subject = '';
  String? when;
  var unread = false;
  int? rank;
  int? replyConversationId;
  final threads = <String>[];
}

ChatThread parseConversation(String html) {
  final document = parseDocument(html);
  final root = document.querySelector('#conversation-detail') ?? document.body;
  final form = _replyForm(document);
  final conversationId =
      int.tryParse(root?.attributes['data-id'] ?? '') ??
      int.tryParse(form?.querySelector('input[name="ConversationId"]')?.attributes['value'] ?? '');
  return ChatThread(
    conversationId: conversationId,
    replyToken: form?.querySelector('input[name="__RequestVerificationToken"]')?.attributes['value'],
    replyAction: _action(form) ?? '/profile/conversation/reply',
    deleteMessageUrl: root?.attributes['data-delete-message-url'],
    messages: [
      for (final row in _rows(root))
        ChatMessage(
          id: int.tryParse(row.querySelector('.delete-message')?.attributes['data-id'] ?? ''),
          conversationId: conversationId,
          body: _body(row),
          mine: _mine(row),
        ),
    ].where((message) => message.body.isNotEmpty).toList(),
  );
}

List<Element> _rows(Element? root) {
  if (root == null) return const [];
  final marked = root.querySelectorAll('.conversation-row').where((row) {
    return row.querySelector('.message-text') != null || row.querySelector('.delete-message') != null;
  }).toList();
  if (marked.isNotEmpty) return marked;
  final rows = <Element>[];
  final seen = <Element>{};
  for (final button in root.querySelectorAll('.delete-message')) {
    final row = _bubble(button, root);
    if (seen.add(row)) rows.add(row);
  }
  return rows;
}

Element _bubble(Element node, Element root) {
  var current = node.parent;
  Element? chosen;
  while (current != null && current != root) {
    chosen = current;
    if (current.classes.contains('conversation-row') || current.classes.contains('base-box-row')) return current;
    current = current.parent;
  }
  return chosen ?? node;
}

String _body(Element row) {
  for (final selector in ['.message-text', '.message-body']) {
    final text = elementText(row.querySelector(selector));
    if (text != null) return text;
  }
  final author = elementText(row.querySelector('.user-name')) ?? elementText(row.querySelector('.nickname'));
  var text = elementText(row) ?? '';
  if (author != null && text.startsWith(author)) text = text.substring(author.length).trim();
  return text;
}

bool _mine(Element row) {
  const marks = {'mine', 'own', 'outgoing'};
  if (row.classes.any(marks.contains)) return true;
  final flag = row.attributes['data-mine'];
  return flag == '1' || flag == 'true';
}

Element? _replyForm(Document document) {
  for (final form in document.querySelectorAll('form')) {
    final action = form.attributes['action'] ?? '';
    if (action.contains('/profile/conversation/reply')) return form;
  }
  return null;
}

String? _action(Element? form) {
  final action = form?.attributes['action'];
  if (action == null || action.isEmpty) return null;
  return pathOnly(action);
}

List<PersonHit> parsePeople(String html) {
  final document = parseDocument(html);
  final people = <PersonHit>[];
  final seen = <String>{};
  for (final card in document.querySelectorAll('a.user-item')) {
    final href = card.attributes['href'];
    if (href == null || href.isEmpty) continue;
    final path = pathOnly(href);
    if (!seen.add(path)) continue;
    final name = elementText(card.querySelector('.search--user-nikname')) ?? _slug(path);
    if (name == null || name.isEmpty) continue;
    final image = card.querySelector('img');
    people.add(PersonHit(name: name, path: path, avatarUrl: image == null ? null : imageSource(image)));
  }
  return people;
}

String? _slug(String path) {
  final parts = path.split('/').where((part) => part.isNotEmpty).toList();
  if (parts.isEmpty) return null;
  return Uri.decodeComponent(parts.last);
}
