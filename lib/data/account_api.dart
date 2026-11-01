import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../account_models.dart';
import 'forms.dart';
import 'nini_client.dart';
import 'parsers/parsers.dart';

class AccountApi {
  AccountApi(this._client);

  final NiniClient _client;

  Future<AccountShell> shell() async {
    return parseAccountShell(await _client.get('/profile'));
  }

  Future<List<CountLine>> forumWall() async {
    return parseForumWall(await _post('/profile/home/GetForumWall'));
  }

  Future<List<CountLine>> clinicWall() async {
    return parseClinicWall(await _post('/profile/home/GetClinicWall'));
  }

  Future<AccountSlice> messages({required bool sent, int offset = 0, int pageSize = 20}) {
    final path = sent ? '/profile/Conversation/GetSents' : '/profile/Conversation/GetReceiveds';
    return _list(path, offset: offset, pageSize: pageSize, parse: (json) => parseMessages(json, sent: sent));
  }

  Future<AccountSlice> friends({int offset = 0, int pageSize = 20}) {
    return _list(
      '/profile/contact/GetFriends',
      offset: offset,
      pageSize: pageSize,
      parse: (json) => parseFriends(json, listKey: 'friends'),
    );
  }

  Future<AccountSlice> friendRequests({required bool sent, int offset = 0, int pageSize = 20}) {
    final path = sent ? '/profile/contact/GetSentRequests' : '/profile/contact/GetFriendRequests';
    return _list(
      path,
      offset: offset,
      pageSize: pageSize,
      parse: (json) => parseFriends(json, listKey: sent ? 'sentRequests' : 'receivedRequests'),
    );
  }

  Future<void> acceptFriend(int contactId) => _post('/profile/contact/Accept', body: {'contactId': contactId});

  Future<void> rejectFriend(int contactId) => _post('/profile/contact/Reject', body: {'contactId': contactId});

  Future<void> cancelFriend(int contactId) => _post('/profile/contact/Cancel', body: {'contactId': contactId});

  Future<void> deleteFriend(int contactId) => _post('/profile/contact/Delete', body: {'contactId': contactId});

  Future<void> deleteMessage(int id) => _post('/profile/Conversation/Delete?id=$id');

  Future<AccountSlice> topics(String path, {int offset = 0, int pageSize = 20, int orderBy = 0}) {
    return _list(path, offset: offset, pageSize: pageSize, orderBy: orderBy, parse: parseTopics);
  }

  Future<AccountSlice> posts(String path, {int offset = 0, int pageSize = 20}) {
    return _list(path, offset: offset, pageSize: pageSize, parse: parsePosts);
  }

  Future<AccountSlice> questions(String path, {int offset = 0, int pageSize = 20}) {
    return _list(path, offset: offset, pageSize: pageSize, parse: parseQuestions);
  }

  Future<AccountSlice> comments(String path, {int offset = 0, int pageSize = 20}) {
    return _list(path, offset: offset, pageSize: pageSize, parse: parseComments);
  }

  Future<AccountSlice> photos(String path, {int offset = 0, int pageSize = 20}) {
    return _list(path, offset: offset, pageSize: pageSize, parse: parsePhotos);
  }

  Future<AccountSlice> videos(String path, {int offset = 0, int pageSize = 20}) {
    return _list(path, offset: offset, pageSize: pageSize, parse: parseVideos);
  }

  Future<void> lockTopic(int topicId, {required bool unlock}) {
    return _post('/profile/forumApi/${unlock ? 'UnlockTopic' : 'LockTopic'}', body: {'topicId': topicId});
  }

  Future<void> removeFavoriteTopic(int topicId) {
    return _post('/profile/forumApi/RemoveFavoriteTopic', body: {'topicId': topicId});
  }

  Future<void> removeFavoritePost(int postId) {
    return _post('/profile/forumApi/RemoveFavoritePost', body: {'postId': postId});
  }

  Future<void> removeFavoriteQuestion(int id) => _post('/profile/clinic/RemoveFavoriteQuestion?id=$id');

  Future<void> removePhoto(int id) => _post('/profile/photo/RemovePhoto?id=$id');

  Future<void> removeFavoritePhoto(int id) => _post('/profile/photo/RemoveFavorite?id=$id');

  Future<void> removeVideo(int id) => _post('/profile/video/RemoveVideo?id=$id');

  Future<void> removeFavoriteVideo(int id) => _post('/profile/video/RemoveFavorite?id=$id');

  Future<NoticePage> notifications() async {
    return parseNotifications(await _client.get('/profile/notification'));
  }

  Future<void> postFields(String path, Map<String, String> fields) async {
    final response = await _client.postForm(path, fields, referer: '$niniOrigin/profile/notification');
    final errors = formErrors(response.body);
    if (errors != null) throw NiniException(errors);
    if (response.statusCode >= 400) throw NiniException('عملیات انجام نشد.');
  }

  Future<PrivateAccount> privateInfo() async => parsePrivateAccount(await _post('/profile/setting/GetUserPrivateInfo'));

  Future<ProfileAccount> profileInfo() async => parseProfileAccount(await _post('/profile/setting/GetUserProfileInfo'));

  Future<ParentingAccount> parenting() async => parseParenting(await _post('/profile/setting/GetParentingInfo'));

  Future<List<MailNotice>> mailNotices() async => parseMailNotices(await _post('/profile/setting/GetNotificationSettings'));

  Future<void> changeName({required String name, required String family}) {
    return _post('/profile/setting/ChangeNameFamily', body: {'name': name, 'family': family});
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) {
    return _post(
      '/profile/setting/ChangePassword',
      body: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      },
    );
  }

  Future<void> editProfile(Map<String, Object?> fields) => _post('/profile/setting/EditProfile', body: fields);

  Future<void> addEmail(String email) => _post('/profile/setting/AddEmail', body: {'email': email});

  Future<void> removeEmail(int id) => _post('/profile/setting/RemoveEmail', body: {'userIdentityEmailId': id});

  Future<void> primaryEmail(int id) => _post('/profile/setting/SetPrimaryEmail', body: {'userIdentityEmailId': id});

  Future<void> resendEmail(int id) {
    return _post('/profile/setting/ResendEmailConfirmationLink', body: {'userIdentityEmailId': id});
  }

  Future<void> addPhone(String phoneNumber) {
    return _post('/profile/setting/AddPhoneNumber', body: {'phoneNumber': phoneNumber});
  }

  Future<void> removePhone(int id) => _post('/profile/setting/RemovePhoneNumber?userIdentityPhoneNumberId=$id');

  Future<void> primaryPhone(int id) => _post('/profile/setting/SetPrimaryPhoneNumber?userIdentityPhoneNumberId=$id');

  Future<void> sendPhoneCode(int id) {
    return _post('/profile/setting/SendPhoneNemberCode', body: {'userIdentityPhoneNumberId': id});
  }

  Future<void> verifyPhone({required int id, required String code}) {
    return _post('/profile/setting/VerifyPhoneNumber', body: {'code': code, 'userIdentityPhoneNumberId': id});
  }

  Future<void> addChild({required String name, required int genderType, required String birthDate}) {
    return _post('/profile/setting/AddChild', body: {'name': name, 'gendertype': genderType, 'birthdate': birthDate});
  }

  Future<void> editChild({
    required int childId,
    required String name,
    required int genderType,
    required String birthDate,
  }) {
    return _post(
      '/profile/setting/EditChild',
      body: {'childId': childId, 'name': name, 'gendertype': genderType, 'birthdate': birthDate},
    );
  }

  Future<void> removeChild(int childId) => _post('/profile/setting/RemoveChild', body: {'childId': childId});

  Future<void> addConceive() => _post('/profile/setting/AddConceive');

  Future<void> removeConceive() => _post('/profile/setting/RemoveConceive');

  Future<void> removePregnancyTicker() => _post('/profile/setting/RemovePregnancyTicker');

  Future<void> saveMailNotices(List<MailNotice> notices) {
    return _post('/profile/setting/SaveNotificationSettings', body: {'NotificationSettings': notices.map((item) => item.toJson()).toList()});
  }

  Future<MessageDraft> messageDraft() async {
    final html = await _client.get('/profile/conversation/create');
    final draft = parseMessageDraft(html);
    if (draft == null) throw NiniException('فرم پیام پیدا نشد.');
    return draft;
  }

  Future<List<AccountChoice>> searchRecipients(String url, String term) async {
    final base = Uri.parse(niniOrigin).resolve(url);
    final resolved = base.replace(queryParameters: {...base.queryParameters, 'term': term});
    try {
      final body = await _client.get(resolved.toString());
      final trimmed = body.trim();
      if (trimmed.startsWith('{') || trimmed.startsWith('[')) return parseChoices(jsonDecode(trimmed));
    } catch (_) {}
    return parseChoices(await _post(resolved.toString()));
  }

  Future<WebForm> uploadForm({required String path, required String action, required String title}) async {
    final html = await _client.get(path);
    final form = parseUploadForm(html, actionContains: action, title: title);
    if (form == null) throw NiniException('فرم پیدا نشد.');
    return form;
  }

  Future<PageAction> pageAction(String path, {String? title}) async {
    return parsePageAction(await _client.get(path), title: title);
  }

  Future<String?> submitForm(WebForm form, Map<String, String> edits) async {
    final response = await _client.postForm(form.action, form.valuesWith(edits), referer: '$niniOrigin/profile');
    return _formFailure(response);
  }

  Future<String?> submitUpload({
    required WebForm form,
    required Map<String, String> fields,
    required List<({String name, String filename, Uint8List bytes})> files,
  }) async {
    final response = await _client.postMultipart(
      form.action,
      fields: fields,
      files: [
        for (final file in files) http.MultipartFile.fromBytes(file.name, file.bytes, filename: file.filename),
      ],
      referer: '$niniOrigin/profile',
    );
    return _formFailure(response);
  }

  Future<AccountSlice> _list(
    String path, {
    required AccountSlice Function(Object? json) parse,
    int offset = 0,
    int pageSize = 20,
    int? orderBy,
  }) async {
    return parse(await _post(path, offset: offset, pageSize: pageSize, orderBy: orderBy));
  }

  Future<Object?> _post(
    String path, {
    Object? body,
    int? offset,
    int? pageSize,
    int? orderBy,
  }) async {
    final resolved = Uri.parse(niniOrigin).resolve(path);
    final query = {
      ...resolved.queryParameters,
      if (offset != null) 'offset': '$offset',
      if (pageSize != null) 'pageSize': '$pageSize',
      if (orderBy != null) 'orderBy': '$orderBy',
    };
    final target = resolved.replace(queryParameters: query.isEmpty ? null : query);
    final response = await _client.postJson(target.toString(), jsonBody: body, referer: '$niniOrigin$path');
    return decodeAccountBody(response);
  }

  String? _formFailure(NiniFetch response) {
    final errors = formErrors(response.body);
    if (errors != null) return errors;
    if (response.statusCode >= 400) return accountErrorMessage(response.body) ?? 'ذخیره انجام نشد.';
    return null;
  }
}
