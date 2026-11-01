import 'dart:convert';

import 'package:html/dom.dart';

import '../../account_models.dart';
import '../forms.dart';
import '../nini_client.dart';
import 'form_parser.dart';
import 'html_utils.dart';

AccountShell parseAccountShell(String html) {
  final document = parseDocument(html);
  final menu = document.querySelector('.side-menu');
  final entries = <AccountMenuEntry>[];
  final seen = <String>{};
  if (menu != null) _walkMenu(menu, entries, seen);
  final name = elementText(document.querySelector('.nickname-header')) ??
      elementText(document.querySelector('h3')) ??
      '';
  final avatar = document.querySelector('.side-menu img') ?? document.querySelector('.profilepic-link img');
  final joinedMatch = RegExp(r'عضویت\s*:?\s*([0-9۰-۹/]+)').firstMatch(menu?.text ?? '');
  String? publicPath;
  for (final entry in entries) {
    final path = entry.path;
    if (path != null && path.startsWith('/user/')) {
      publicPath = path;
      break;
    }
  }
  return AccountShell(
    name: name,
    avatarUrl: avatar == null ? null : imageSource(avatar),
    joined: joinedMatch?.group(1),
    publicPath: publicPath,
    entries: entries,
  );
}

void _walkMenu(Node node, List<AccountMenuEntry> entries, Set<String> seen, {bool linksOnly = false}) {
  if (node is Text) {
    if (linksOnly) return;
    final title = collapseSpace(node.text);
    if (title.length < 3 || title.contains('عضویت')) return;
    if (seen.add('heading|$title')) entries.add(AccountMenuEntry(title: title));
    return;
  }
  if (node is! Element) return;
  if (node.classes.contains('namebox') || node.classes.contains('profilepic-link')) return;
  final header = linksOnly || node.classes.contains('side-header');
  if (node.localName == 'a') {
    final title = elementText(node);
    final href = node.attributes['href'];
    if (title == null || href == null || href.isEmpty || href == '#') return;
    final path = pathOnly(href);
    if (seen.add('$path|$title')) entries.add(AccountMenuEntry(title: title, path: path));
    return;
  }
  for (final child in node.nodes) {
    _walkMenu(child, entries, seen, linksOnly: header);
  }
}

String? accountSection(String path) {
  final normalized = pathOnly(path);
  if (normalized == '/profile') return 'dashboard';
  if (normalized.startsWith('/profile/setting')) return 'settings';
  if (normalized.startsWith('/profile/conversation')) return 'messages';
  if (normalized.startsWith('/profile/contact')) return 'friends';
  if (normalized.startsWith('/profile/notification')) return 'notifications';
  if (normalized.startsWith('/profile/forum')) return 'forum';
  if (normalized.startsWith('/profile/clinic')) return 'clinic';
  if (normalized.startsWith('/profile/video')) return 'video';
  if (normalized.startsWith('/profile/photo')) return 'photo';
  if (normalized.startsWith('/profile/profilepicture')) return 'picture';
  return null;
}

List<CountLine> parseForumWall(Object? json) {
  final map = _asMap(json);
  return [
    CountLine(label: 'پست‌ها', value: _int(map, 'TotalPostCount') ?? 0),
    CountLine(label: 'تاپیک‌ها', value: _int(map, 'TotalTopicCount') ?? 0),
    CountLine(label: 'پست‌های جدید تاپیک‌های من', value: _int(map, 'CreatedNewPostCount') ?? 0),
    CountLine(label: 'پست‌های جدید ذخیره‌شده‌ها', value: _int(map, 'FavoriteNewPostCount') ?? 0),
    CountLine(label: 'پست‌های جدید تاپیک‌هایی که شرکت کردم', value: _int(map, 'PostedNewPostCount') ?? 0),
  ];
}

List<CountLine> parseClinicWall(Object? json) {
  final map = _asMap(json);
  return [
    CountLine(label: 'سوالات پاسخ‌داده‌شده', value: _int(map, 'AnsweredQuestionCount') ?? 0),
    CountLine(label: 'در انتظار پاسخ', value: _int(map, 'WaitingForAnswerQuestionCount') ?? 0),
    CountLine(label: 'سوالات ذخیره‌شده', value: _int(map, 'FavoriteAnsweredQuestionCount') ?? 0),
  ];
}

AccountSlice parseMessages(Object? json, {required bool sent}) {
  final map = _asMap(json);
  final raw = map[sent ? 'sentMessages' : 'receivedMessages'];
  final records = <AccountRecord>[];
  if (raw is List) {
    for (final item in raw) {
      if (item is! Map) continue;
      final subject = _string(item, 'Subject') ?? '';
      final nickname = _string(item, 'Nickname');
      final day = _string(item, 'Day');
      final time = _string(item, 'TimeOfDay');
      records.add(
        AccountRecord(
          id: _int(item, 'ConversationId'),
          peer: nickname,
          title: subject.isEmpty ? (nickname ?? 'پیام') : subject,
          subtitle: [nickname, day, time].whereType<String>().where((part) => part.isNotEmpty).join(' · '),
          imageUrl: _string(item, 'Avatar'),
          path: _string(item, 'ConversationUrl'),
          unread: _int(item, 'Readed') == 0,
        ),
      );
    }
  }
  return AccountSlice(records: records, total: _int(map, 'totalCount') ?? records.length);
}

AccountSlice parseFriends(Object? json, {required String listKey}) {
  final map = _asMap(json);
  final raw = map[listKey] ?? map['friends'] ?? map['receivedRequests'] ?? map['sentRequests'];
  final records = <AccountRecord>[];
  if (raw is List) {
    for (final item in raw) {
      if (item is! Map) continue;
      records.add(
        AccountRecord(
          id: _int(item, 'ContactId'),
          title: _string(item, 'Nickname') ?? 'دوست',
          imageUrl: _string(item, 'Avatar'),
          path: _string(item, 'UserUrl'),
          messagePath: _string(item, 'SentMessageUrl'),
        ),
      );
    }
  }
  return AccountSlice(records: records, total: _int(map, 'totalCount') ?? records.length);
}

AccountSlice parseTopics(Object? json) {
  return _slice(json, (item) {
    final subject = _string(item, 'Subject') ?? 'تاپیک';
    final creator = _string(item, 'CreatorName');
    final total = _int(item, 'TotalPostCount');
    final fresh = _int(item, 'NewPostCount');
    return AccountRecord(
      id: _int(item, 'ForumTopicId'),
      title: subject,
      subtitle: [
        creator,
        if (total != null) '$total پست',
        if (fresh != null && fresh > 0) '$fresh پست جدید',
      ].whereType<String>().where((part) => part.isNotEmpty).join(' · '),
      path: _string(item, 'TopicUrl'),
      open: _openState(item['OpenCloseState'] ?? item['openCloseState']),
    );
  });
}

AccountSlice parsePosts(Object? json) {
  return _slice(json, (item) {
    final message = _string(item, 'Message') ?? _string(item, 'Subject') ?? 'پست';
    return AccountRecord(
      id: _int(item, 'ForumPostId') ?? _int(item, 'PostId'),
      title: message,
      subtitle: _string(item, 'Subject'),
      path: _string(item, 'PostUrl') ?? _string(item, 'TopicUrl'),
    );
  });
}

AccountSlice parseQuestions(Object? json) {
  return _slice(json, (item) {
    return AccountRecord(
      id: _int(item, 'QuestionId'),
      title: _string(item, 'Title') ?? 'سوال',
      subtitle: [
        _string(item, 'CreatedOn'),
        if (_int(item, 'CommentCount') != null) '${_int(item, 'CommentCount')} نظر',
      ].whereType<String>().where((part) => part.isNotEmpty).join(' · '),
      path: _string(item, 'QuestionUrl'),
    );
  });
}

AccountSlice parseComments(Object? json) {
  return _slice(json, (item) {
    return AccountRecord(
      id: _int(item, 'CommentId'),
      title: _string(item, 'CommentBody') ?? 'نظر',
      subtitle: _string(item, 'CommentCreatedOn'),
      path: _string(item, 'QuestionUrl') ?? _string(item, 'PhotoUrl') ?? _string(item, 'VideoUrl'),
    );
  });
}

AccountSlice parsePhotos(Object? json) {
  return _slice(json, (item) {
    return AccountRecord(
      id: _int(item, 'PhotoId'),
      title: _string(item, 'Title') ?? 'عکس',
      imageUrl: _string(item, 'PhotoPath') ?? _string(item, 'PhotoUrl'),
      path: _string(item, 'PhotoUrl'),
      editPath: _string(item, 'PhotoEditUrl'),
    );
  });
}

AccountSlice parseVideos(Object? json) {
  return _slice(json, (item) {
    return AccountRecord(
      id: _int(item, 'VideoId'),
      title: _string(item, 'Title') ?? 'ویدیو',
      imageUrl: _string(item, 'VideoPath'),
      path: _string(item, 'VideoUrl'),
      editPath: _string(item, 'VideoEditUrl'),
    );
  });
}

NoticePage parseNotifications(String html) {
  final document = parseDocument(html);
  final root = document.querySelector('#notification');
  if (root == null) return const NoticePage(records: []);
  final deleteUrl = root.querySelector('[data-delete-url]')?.attributes['data-delete-url'] ??
      document.querySelector('[data-delete-url]')?.attributes['data-delete-url'];
  final records = <AccountRecord>[];
  final rows = root.querySelectorAll('li, tr, .base-box-row, .notification-item, .comment-row');
  for (final row in rows) {
    final title = elementText(row.querySelector('a')) ?? elementText(row);
    if (title == null || title.isEmpty) continue;
    final checkbox = row.querySelector('.check-remove');
    final idText = checkbox?.attributes['value'] ?? row.attributes['data-id'];
    final action = row.querySelector('[data-api]')?.attributes['data-api'] ?? deleteUrl;
    final fields = <String, String>{};
    for (final input in row.querySelectorAll('input')) {
      final name = input.attributes['name'];
      if (name == null || name.isEmpty) continue;
      fields[name] = input.attributes['value'] ?? '';
    }
    if (fields.isEmpty && idText != null && idText.isNotEmpty) fields['ids'] = idText;
    records.add(
      AccountRecord(
        title: title,
        path: row.querySelector('a')?.attributes['href'],
        id: int.tryParse(idText ?? ''),
        action: action,
        fields: fields,
      ),
    );
  }
  return NoticePage(records: records, deleteUrl: deleteUrl);
}

MessageDraft? parseMessageDraft(String html) {
  final document = parseDocument(html);
  Element? form;
  for (final candidate in document.querySelectorAll('form')) {
    final action = candidate.attributes['action'] ?? '';
    if (action.contains('/profile/conversation/send')) {
      form = candidate;
      break;
    }
  }
  if (form == null) return null;
  final parsed = webFormFrom(form, title: 'پیام جدید');
  if (parsed == null) return null;
  return MessageDraft(form: parsed, searchUrl: _searchUrl(html, form));
}

WebForm? parseUploadForm(String html, {required String actionContains, required String title}) {
  final document = parseDocument(html);
  for (final form in document.querySelectorAll('form')) {
    final action = form.attributes['action'] ?? '';
    if (!action.contains(actionContains)) continue;
    return webFormFrom(form, title: title);
  }
  return null;
}

PageAction parsePageAction(String html, {String? title}) {
  final document = parseDocument(html);
  WebForm? form;
  for (final candidate in document.querySelectorAll('form')) {
    final action = candidate.attributes['action'] ?? '';
    if (action.contains('/search') || action.contains('/imen/logoff') || action.isEmpty) continue;
    form = webFormFrom(candidate, title: title);
    if (form != null) break;
  }
  final body = document.querySelector('.section-body') ?? document.querySelector('.message-box');
  final text = elementText(body);
  return PageAction(text: text, form: form);
}

class PageAction {
  const PageAction({this.text, this.form});

  final String? text;
  final WebForm? form;
}

List<AccountChoice> parseChoices(Object? json) {
  final choices = <AccountChoice>[];
  void add(Object? item) {
    if (item is! Map) return;
    final id = item['id'] ?? item['Id'] ?? item['UserId'];
    final label = item['text'] ?? item['Text'] ?? item['Name'] ?? item['Nickname'];
    if (id == null || label is! String || label.isEmpty) return;
    choices.add(AccountChoice(id: '$id', label: label));
  }

  if (json is List) {
    for (final item in json) {
      add(item);
    }
    return choices;
  }
  final map = _asMap(json);
  final results = map['results'] ?? map['Results'] ?? map['items'] ?? map['Items'];
  if (results is List) {
    for (final item in results) {
      add(item);
    }
  }
  return choices;
}

PrivateAccount parsePrivateAccount(Object? json) {
  final map = _asMap(json);
  return PrivateAccount(
    nickname: _string(map, 'Nickname'),
    emails: _channels(map['Emails'], idKey: 'UserIdentityEmailId', valueKey: 'Email'),
    phones: _channels(map['PhoneNumbers'], idKey: 'UserIdentityPhoneNumberId', valueKey: 'PhoneNumber'),
  );
}

ProfileAccount parseProfileAccount(Object? json) {
  final map = _asMap(json);
  return ProfileAccount(
    fields: Map<String, Object?>.from(map),
    gender: _string(map, 'GenderTypeString'),
    birthDate: _string(map, 'PersianBirthDate'),
    signature: _string(map, 'SignatureMessage'),
    allowSignature: map['AllowSignature'] == true,
  );
}

ParentingAccount parseParenting(Object? json) {
  final map = _asMap(json);
  final children = <ChildInfo>[];
  final raw = map['children'] ?? map['Children'];
  if (raw is List) {
    for (final item in raw) {
      if (item is! Map) continue;
      children.add(
        ChildInfo(
          id: _int(item, 'childId') ?? _int(item, 'ChildId') ?? _int(item, 'Id'),
          name: _string(item, 'name') ?? _string(item, 'Name') ?? '',
          genderType: _int(item, 'gendertype') ?? _int(item, 'GenderType'),
          birthDate: _string(item, 'birthdate') ?? _string(item, 'BirthDate') ?? _string(item, 'PersianBirthDate'),
        ),
      );
    }
  }
  return ParentingAccount(
    parentingType: _int(map, 'parentingType') ?? _int(map, 'ParentingType'),
    children: children,
    embryo: _stringMap(map['embryo'] ?? map['Embryo']),
    conceive: _stringMap(map['conceive'] ?? map['Conceive']),
  );
}

List<MailNotice> parseMailNotices(Object? json) {
  if (json is! List) return const [];
  final notices = <MailNotice>[];
  for (final item in json) {
    if (item is! Map) continue;
    final id = _int(item, 'Id');
    final title = _string(item, 'Title');
    if (id == null || title == null) continue;
    notices.add(MailNotice(id: id, title: title, checked: item['Checked'] == true));
  }
  return notices;
}

Object? decodeAccountBody(NiniFetch response) {
  final body = response.body.trim();
  if (response.statusCode >= 400) {
    throw NiniException(accountErrorMessage(body) ?? 'پاسخ سرور نامعتبر بود.');
  }
  if (body.isEmpty) return null;
  try {
    return jsonDecode(body);
  } catch (_) {
    return body;
  }
}

String? accountErrorMessage(String body) {
  if (body.isEmpty) return null;
  try {
    final decoded = jsonDecode(body);
    if (decoded is String && decoded.trim().isNotEmpty) return decoded.trim();
    if (decoded is Map) {
      for (final key in ['Message', 'message', 'error']) {
        final value = decoded[key];
        if (value is String && value.trim().isNotEmpty) return value.trim();
      }
    }
  } catch (_) {
    if (!body.contains('<') && body.length < 240) return body;
  }
  return null;
}

String? _searchUrl(String html, Element form) {
  final field = form.querySelector('[name="UserIds"]');
  for (final node in [field, field?.parent, form]) {
    if (node == null) continue;
    for (final key in ['data-ajax-url', 'data-url', 'data-ajax--url', 'data-search-url']) {
      final value = node.attributes[key];
      if (value != null && value.isNotEmpty) return value;
    }
  }
  final match = RegExp(
    "UserIds[\\s\\S]{0,500}?url\\s*[:=]\\s*['\"]([^'\"]+)",
  ).firstMatch(html);
  return match?.group(1);
}

AccountSlice _slice(Object? json, AccountRecord Function(Map<dynamic, dynamic> item) mapItem) {
  final map = json is Map ? json : _asMap(json);
  final list = json is List ? json : _firstList(map);
  final records = <AccountRecord>[];
  for (final item in list) {
    if (item is Map) records.add(mapItem(item));
  }
  final total = json is Map ? (_int(map, 'totalCount') ?? _int(map, 'TotalCount') ?? records.length) : records.length;
  return AccountSlice(records: records, total: total);
}

List<dynamic> _firstList(Map<dynamic, dynamic> map) {
  for (final key in ['items', 'Items', 'data', 'Data', 'topics', 'Topics', 'posts', 'Posts']) {
    final value = map[key];
    if (value is List) return value;
  }
  for (final value in map.values) {
    if (value is List) return value;
  }
  return const [];
}

List<ContactChannel> _channels(Object? raw, {required String idKey, required String valueKey}) {
  if (raw is! List) return const [];
  final channels = <ContactChannel>[];
  for (final item in raw) {
    if (item is! Map) continue;
    final id = _int(item, idKey);
    final value = _string(item, valueKey);
    if (id == null || value == null) continue;
    channels.add(
      ContactChannel(
        id: id,
        value: value,
        primary: item['IsPrimary'] == true,
        confirmed: item['PhoneNumberConfirmed'] == true || item['EmailConfirmed'] == true,
      ),
    );
  }
  return channels;
}

Map<dynamic, dynamic> _asMap(Object? json) => json is Map ? json : const {};

Map<String, Object?> _stringMap(Object? json) {
  return {for (final entry in _asMap(json).entries) '${entry.key}': entry.value};
}

Object? _field(Map<dynamic, dynamic> map, String name) {
  if (map.containsKey(name)) return map[name];
  final lower = name.toLowerCase();
  for (final entry in map.entries) {
    if ('${entry.key}'.toLowerCase() == lower) return entry.value;
  }
  return null;
}

int? _int(Map<dynamic, dynamic> map, String name) {
  final value = _field(map, name);
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

String? _string(Map<dynamic, dynamic> map, String name) {
  final value = _field(map, name);
  if (value == null) return null;
  final text = '$value'.trim();
  return text.isEmpty ? null : text;
}

bool? _openState(Object? value) {
  if (value == null) return null;
  if (value is bool) return !value;
  if (value is num) {
    if (value == 0) return true;
    if (value == 1) return false;
  }
  final text = '$value'.toLowerCase();
  if (text == '0' || text == 'open' || text == 'false') return true;
  if (text == '1' || text == 'closed' || text == 'true') return false;
  return null;
}
