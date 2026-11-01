import 'forms.dart';
import 'parsers/html_utils.dart';

const topicLockedMessage = 'این تاپیک قفل شده است و ثبت پست جدید در آن امکان پذیر نیست';

const signInFailure = 'نام کاربری یا کلمه عبور خود را اشتباه وارد کرده اید.';

String iranMobile(String input) {
  final digits = normalizeDigits(input).replaceAll(RegExp(r'\D'), '');
  var local = digits;
  if (local.startsWith('0098')) {
    local = local.substring(4);
  } else if (local.startsWith('98')) {
    local = local.substring(2);
  } else if (local.startsWith('0')) {
    local = local.substring(1);
  }
  return '+98$local';
}

String plainFromHtml(String html) {
  return html
      .replaceAll(RegExp(r'<[^>]+>'), ' ')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

String replyQuote(String postId, String plain) {
  var text = plain.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (text.length > 100) text = '${text.substring(0, 100)} ...';
  return '[QUOTE=$postId]$text[/QUOTE]\n';
}

String composeMessage(String text) {
  final trimmed = text.trim();
  final quote = RegExp(r'^\[QUOTE=(\d+)\]([\s\S]*?)\[/QUOTE\]\s*').firstMatch(trimmed);
  if (quote != null) {
    final rest = trimmed.substring(quote.end).trim();
    final body = rest.isEmpty ? '<p><br></p>' : '<p>${_escape(rest)}</p>';
    return '<p>[QUOTE=${quote.group(1)}]${_escape(quote.group(2)!)}[/QUOTE]</p>$body';
  }
  return '<p>${_escape(trimmed).replaceAll('\n', '<br>')}</p>';
}

Map<String, String> signInFields({
  required String username,
  required String password,
  required String token,
  required bool remember,
}) {
  return {
    'ReturnUrl': '/discussion',
    'ShowCaptcha': 'False',
    'UserName': username.trim(),
    'Password': password,
    'RememberMe': remember ? 'true' : 'false',
    '__RequestVerificationToken': token,
  };
}

Map<String, String> signUpFields({
  required String phone,
  required String password,
  required String confirmPassword,
  required String captcha,
  required String token,
}) {
  return {
    'PhoneNumber': iranMobile(phone),
    'Password': password,
    'ConfirmPassword': confirmPassword,
    'Captcha': captcha.trim(),
    '__RequestVerificationToken': token,
  };
}

Map<String, String> newTopicFields({
  required String subject,
  required String message,
  required int categoryId,
  required int forumId,
  required String token,
}) {
  return {
    'Subject': subject.trim(),
    'Message': composeMessage(message),
    'CategoryId': '$categoryId',
    'ForumId': '$forumId',
    '__RequestVerificationToken': token,
  };
}

Map<String, String> replyFields({
  required int topicId,
  required String message,
  required String token,
}) {
  return {
    'TopicId': '$topicId',
    'Message': composeMessage(message),
    '__RequestVerificationToken': token,
  };
}

Map<String, String> webFormFields(WebForm form, Map<String, String> edits) => form.valuesWith(edits);

String _escape(String input) {
  return input
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');
}
