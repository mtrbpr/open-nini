import 'dart:convert';

import 'package:html/dom.dart';

import '../../models.dart';
import '../compose.dart';
import '../forms.dart';
import 'html_utils.dart';

String? formErrors(String html) {
  final document = parseDocument(html);
  final messages = <String>[];
  for (final node in document.querySelectorAll('.validation-summary-errors li, .field-validation-error')) {
    final text = elementText(node);
    if (text != null && !messages.contains(text)) messages.add(text);
  }
  if (messages.isEmpty) return null;
  return messages.join('\n');
}

String? signInError(String html) {
  if (html.contains('اشتباه وارد کرده')) return signInFailure;
  final errors = formErrors(html);
  if (errors != null && html.contains('/imen/signin')) return errors;
  return null;
}

String? profilePathFromHtml(String html) {
  final header = parseDocument(html).querySelector('header');
  if (header == null) return null;
  String? fallback;
  for (final anchor in header.querySelectorAll('a[href*="/user/"]')) {
    final path = pathOnly(anchor.attributes['href'] ?? '');
    if (_ownProfile.hasMatch(path)) return path;
    if (fallback == null && _userPath.hasMatch(path)) fallback = path;
  }
  return fallback;
}

final _ownProfile = RegExp(r'^/user/discussion/[0-9a-fA-F-]+/[^/]+$');
final _userPath = RegExp(r'^/user/[0-9a-fA-F-]+/[^/]+$');

String? tokenForAction(String html, String action, {String? requiredField}) {
  final document = parseDocument(html);
  for (final form in document.querySelectorAll('form')) {
    final formAction = form.attributes['action'] ?? '';
    if (formAction != action && !formAction.endsWith(action)) continue;
    if (requiredField != null && form.querySelector('input[name="$requiredField"]') == null) continue;
    final token = form.querySelector('input[name="__RequestVerificationToken"]')?.attributes['value'];
    if (token != null && token.isNotEmpty) return token;
  }
  return null;
}

WebForm? parseProfileCompleteForm(String html) {
  final document = parseDocument(html);
  final root = document.querySelector('#popup-profile-complete-form');
  if (root == null) return null;
  final form = root.localName == 'form' ? root : root.querySelector('form');
  if (form == null) return null;
  return webFormFrom(form, title: 'تکمیل نمایه');
}

WebForm? parseVerificationForm(String html) {
  final document = parseDocument(html);
  for (final form in document.querySelectorAll('form')) {
    final action = form.attributes['action'] ?? '';
    if (action.contains('/search') || action.contains('/imen/signin') || action.contains('/imen/signup')) {
      continue;
    }
    final code = _codeField(form);
    if (code == null) continue;
    return webFormFrom(form, title: 'تأیید شماره');
  }
  return null;
}

Element? _codeField(Element form) {
  for (final input in form.querySelectorAll('input')) {
    final name = input.attributes['name'] ?? '';
    final id = input.attributes['id'] ?? '';
    if (name == '__RequestVerificationToken') continue;
    final label = _labelFor(form, input) ?? '';
    final haystack = '$name $id $label';
    if (haystack.contains('کد') || RegExp(r'code|verify|otp', caseSensitive: false).hasMatch(haystack)) {
      return input;
    }
  }
  return null;
}

WebForm? webFormFrom(Element form, {String? title}) {
  final action = form.attributes['action'];
  if (action == null || action.isEmpty) return null;
  final fields = <WebField>[];
  for (final input in form.querySelectorAll('input')) {
    final name = input.attributes['name'];
    if (name == null || name.isEmpty) continue;
    final type = (input.attributes['type'] ?? 'text').toLowerCase();
    if (type == 'submit' || type == 'button' || type == 'image') continue;
    fields.add(
      WebField(
        name: name,
        type: type == 'checkbox' ? 'checkbox' : type,
        label: _labelFor(form, input),
        value: input.attributes['value'] ?? '',
        placeholder: input.attributes['placeholder'],
      ),
    );
  }
  for (final area in form.querySelectorAll('textarea')) {
    final name = area.attributes['name'];
    if (name == null || name.isEmpty) continue;
    fields.add(
      WebField(
        name: name,
        type: 'textarea',
        label: _labelFor(form, area),
        value: area.text,
        placeholder: area.attributes['placeholder'],
      ),
    );
  }
  for (final select in form.querySelectorAll('select')) {
    final name = select.attributes['name'];
    if (name == null || name.isEmpty) continue;
    final options = <WebOption>[];
    String value = '';
    for (final option in select.querySelectorAll('option')) {
      final optionValue = option.attributes['value'] ?? option.text.trim();
      options.add(WebOption(value: optionValue, label: collapseSpace(option.text)));
      if (option.attributes.containsKey('selected')) value = optionValue;
    }
    fields.add(
      WebField(
        name: name,
        type: 'select',
        label: _labelFor(form, select),
        value: value,
        options: options,
      ),
    );
  }
  if (fields.isEmpty) return null;
  return WebForm(action: action, fields: fields, title: title);
}

String? _labelFor(Element form, Element field) {
  final id = field.attributes['id'];
  if (id != null && id.isNotEmpty) {
    for (final label in form.querySelectorAll('label')) {
      if (label.attributes['for'] == id) return elementText(label);
    }
  }
  final parentLabel = field.parent?.localName == 'label' ? field.parent : null;
  return elementText(parentLabel);
}

List<ForumCategory> parseForumCategories(String body) {
  final decoded = jsonDecode(body);
  if (decoded is! List) return const [];
  final categories = <ForumCategory>[];
  for (final item in decoded) {
    if (item is! Map) continue;
    final id = _jsonInt(item['Id']);
    final name = item['Name'];
    if (id == null || name is! String) continue;
    final forums = <ForumOption>[];
    final rawForums = item['Forums'];
    if (rawForums is List) {
      for (final forum in rawForums) {
        if (forum is! Map) continue;
        final forumId = _jsonInt(forum['Id']);
        final forumName = forum['Name'];
        if (forumId == null || forumName is! String) continue;
        forums.add(ForumOption(id: forumId, name: forumName));
      }
    }
    categories.add(ForumCategory(id: id, name: name, forums: forums));
  }
  return categories;
}

int? _jsonInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

String? topicPathFromBody(String body, Uri url) {
  final direct = _topicPath(url.path) ?? _topicPath(url.toString());
  if (direct != null) return direct;
  final trimmed = body.trim();
  if (!trimmed.startsWith('{') && !trimmed.startsWith('[')) return null;
  try {
    final decoded = jsonDecode(trimmed);
    return _pathInJson(decoded);
  } catch (_) {
    return null;
  }
}

String? _pathInJson(Object? value) {
  if (value is String) return _topicPath(value);
  if (value is List) {
    for (final item in value) {
      final found = _pathInJson(item);
      if (found != null) return found;
    }
  }
  if (value is Map) {
    for (final entry in value.entries) {
      final key = '${entry.key}'.toLowerCase();
      if (key.contains('redirect') || key == 'url' || key == 'returnurl' || key == 'location') {
        final found = _pathInJson(entry.value);
        if (found != null) return found;
      }
    }
    for (final entry in value.entries) {
      final found = _pathInJson(entry.value);
      if (found != null) return found;
    }
  }
  return null;
}

String? _topicPath(String value) {
  final link = parseTopicLink(value);
  return link?.path;
}

bool topicIsClosed(Document document) {
  final value = document.querySelector('#post-grid')?.attributes['data-closed'];
  return value != null && value.isNotEmpty && value != '0';
}
