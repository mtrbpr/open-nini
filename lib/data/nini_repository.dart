import 'package:flutter/foundation.dart';

import '../models.dart';
import 'account_api.dart';
import 'compose.dart';
import 'forms.dart';
import 'nini_client.dart';
import 'parsers/parsers.dart';
import 'session_store.dart';

class CaptchaChallenge {
  const CaptchaChallenge({required this.token, required this.image});

  final String token;
  final Uint8List image;
}

class NiniRepository extends ChangeNotifier {
  NiniRepository({NiniClient? client, SessionStore? store})
    : _store = store ?? SecureSessionStore(),
      _client = client ?? NiniClient() {
    _client.onCookiesChanged = _persistSession;
  }

  final NiniClient _client;
  final SessionStore _store;
  DiscussionIndex? _index;
  bool _signedIn = false;
  String? _profilePath;

  bool get signedIn => _signedIn;

  String? get profilePath => _profilePath;

  AccountApi get account => AccountApi(_client);

  Future<void> restore() async {
    try {
      final stored = await _store.read();
      if (stored == null || !stored.signedIn) return;
      _client.restoreCookies(stored.cookies);
      _signedIn = true;
      _profilePath = stored.profilePath;
      notifyListeners();
    } catch (_) {}
  }

  Future<DiscussionIndex> fetchIndex({bool refresh = false}) async {
    if (!refresh && _index != null) return _index!;
    final html = await _client.get('/discussion');
    _index = parseDiscussionIndex(html);
    return _index!;
  }

  Future<BoardPage> fetchBoard(String path, {int page = 1}) async {
    final html = await _client.get(path, page: page);
    return parseBoardPage(html, page: page);
  }

  Future<TopicPage> fetchTopic(String path, {int page = 1}) async {
    final html = await _client.get(path, page: page);
    final parsed = parseTopicPage(html, page: page);
    if (page <= 1) return parsed;
    return TopicPage(
      title: parsed.title,
      views: parsed.views,
      posts: parsed.posts.where((post) => !post.isOriginal).toList(),
      page: parsed.page,
      lastPage: parsed.lastPage,
      closed: parsed.closed,
    );
  }

  Future<UserProfile> fetchProfile(String path, {int page = 1}) async {
    final html = await _client.get(path, page: page);
    return parseProfile(html, page: page);
  }

  Future<List<ForumCategory>> fetchCategories() async {
    final body = await _client.get('/discussion/getcategories');
    return parseForumCategories(body);
  }

  Future<AuthOutcome> signIn({
    required String username,
    required String password,
    required bool remember,
  }) async {
    final page = await _client.get('/imen/signin');
    final token = tokenForAction(page, '/imen/signin', requiredField: 'ShowCaptcha');
    if (token == null) return const AuthOutcome(message: 'فرم ورود پیدا نشد.');
    final response = await _client.postForm(
      '/imen/signin',
      signInFields(username: username, password: password, token: token, remember: remember),
      referer: '$niniOrigin/imen/signin',
    );
    return _finishAuth(response);
  }

  Future<CaptchaChallenge> signUpChallenge() async {
    final page = await _client.get('/imen/signup');
    final token = tokenForAction(page, '/imen/signup');
    if (token == null) throw NiniException('فرم ثبت نام پیدا نشد.');
    final image = await _client.getBytes('/captcha/register');
    return CaptchaChallenge(token: token, image: image);
  }

  Future<AuthOutcome> signUp({
    required String phone,
    required String password,
    required String confirmPassword,
    required String captcha,
    required String token,
  }) async {
    final response = await _client.postForm(
      '/imen/signup',
      signUpFields(
        phone: phone,
        password: password,
        confirmPassword: confirmPassword,
        captcha: captcha,
        token: token,
      ),
      referer: '$niniOrigin/imen/signup',
    );
    return _finishAuth(response);
  }

  Future<AuthOutcome> submitWebForm(WebForm form, Map<String, String> edits) async {
    final response = await _client.postForm(
      form.action,
      webFormFields(form, edits),
      referer: niniPageUri(form.action, 1).toString(),
    );
    final errors = formErrors(response.body);
    if (errors != null) return AuthOutcome(message: errors);
    if (response.url.path.contains('/imen/signin') || response.url.path.contains('/imen/signup')) {
      return _finishAuth(response);
    }
    final verification = parseVerificationForm(response.body);
    if (verification != null) return AuthOutcome(nextForm: verification);
    if (!_signedIn) return _finishAuth(response);
    return const AuthOutcome(signedIn: true);
  }

  Future<void> signOut() async {
    _signedIn = false;
    _profilePath = null;
    _client.clearCookies();
    await _store.clear();
    notifyListeners();
  }

  Future<ComposeOutcome> createTopic({
    required String boardPath,
    required String subject,
    required String message,
    required int categoryId,
    required int forumId,
  }) async {
    if (!_signedIn) return const ComposeOutcome(message: 'برای ارسال باید وارد شوید.');
    final html = await _client.get(boardPath);
    final blocked = _profileGate(html);
    if (blocked != null) return blocked;
    final token = tokenForAction(html, '/discussion/forum/createtopic');
    if (token == null) return const ComposeOutcome(message: 'فرم تاپیک پیدا نشد.');
    final response = await _client.postForm(
      '/discussion/forum/createtopic',
      newTopicFields(
        subject: subject,
        message: message,
        categoryId: categoryId,
        forumId: forumId,
        token: token,
      ),
      referer: niniPageUri(boardPath, 1).toString(),
    );
    return _finishCompose(response);
  }

  Future<ComposeOutcome> createReply({
    required String topicPath,
    required int topicId,
    required String message,
  }) async {
    if (!_signedIn) return const ComposeOutcome(message: 'برای ارسال باید وارد شوید.');
    final html = await _client.get(topicPath);
    if (parseTopicPage(html).closed) return const ComposeOutcome(message: topicLockedMessage);
    final blocked = _profileGate(html);
    if (blocked != null) return blocked;
    final token = tokenForAction(html, '/discussion/create');
    if (token == null) return const ComposeOutcome(message: 'فرم پاسخ پیدا نشد.');
    final response = await _client.postForm(
      '/discussion/create',
      replyFields(topicId: topicId, message: message, token: token),
      referer: niniPageUri(topicPath, 1).toString(),
    );
    return _finishCompose(response);
  }

  ComposeOutcome? _profileGate(String html) {
    final form = parseProfileCompleteForm(html);
    if (form == null) return null;
    return ComposeOutcome(profileForm: form);
  }

  ComposeOutcome _finishCompose(NiniFetch response) {
    final gate = _profileGate(response.body);
    if (gate != null && !response.url.path.contains('/discussion/topic/')) return gate;
    if (response.url.path.contains('/imen/signin')) {
      return const ComposeOutcome(message: 'برای ارسال باید وارد شوید.');
    }
    final topicPath = topicPathFromBody(response.body, response.url);
    if (topicPath != null) return ComposeOutcome(topicPath: topicPath);
    final errors = formErrors(response.body);
    if (errors != null) return ComposeOutcome(message: errors);
    return const ComposeOutcome(message: 'ارسال انجام نشد.');
  }

  Future<AuthOutcome> _finishAuth(NiniFetch response) async {
    final invalid = signInError(response.body);
    final errors = formErrors(response.body);
    final verification = parseVerificationForm(response.body);
    final onSignIn = response.url.path.contains('/imen/signin');
    String branch;
    if (onSignIn && invalid != null) {
      branch = 'credential-error';
    } else if (verification != null && response.url.path.contains('/imen/')) {
      branch = 'verification';
    } else if (errors != null) {
      branch = 'form-errors';
    } else if (response.url.path.contains('/imen/signup')) {
      branch = 'signup-page';
    } else if (onSignIn) {
      branch = 'still-signin';
    } else {
      branch = 'signed-in';
    }
    if (branch == 'credential-error') return AuthOutcome(message: invalid);
    if (branch == 'verification') return AuthOutcome(nextForm: verification);
    if (branch == 'form-errors') return AuthOutcome(message: errors);
    if (branch == 'signup-page') return const AuthOutcome(message: 'ثبت نام انجام نشد.');
    if (branch == 'still-signin') return const AuthOutcome(message: 'ورود انجام نشد.');
    _signedIn = true;
    _profilePath = profilePathFromHtml(response.body) ?? await _profileFromHome();
    await _persistSession();
    notifyListeners();
    return const AuthOutcome(signedIn: true);
  }

  Future<String?> _profileFromHome() async {
    try {
      final html = await _client.get('/discussion');
      return profilePathFromHtml(html);
    } catch (_) {
      return null;
    }
  }

  Future<void> _persistSession() async {
    if (!_signedIn) return;
    try {
      await _store.write(
        StoredSession(cookies: _client.cookies, signedIn: true, profilePath: _profilePath),
      );
    } catch (_) {}
  }
}
