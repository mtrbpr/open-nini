import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:open_nini/data/compose.dart';
import 'package:open_nini/data/cookie_jar.dart';
import 'package:open_nini/data/parsers/parsers.dart';

void main() {
  String fixture(String name) => File('test/fixtures/$name').readAsStringSync();

  test('profile page reads the member and their topics', () {
    final profile = parseProfile(fixture('profile.html'));

    expect(profile.name, '_julia');
    expect(profile.avatarUrl, contains('woman3.svg'));
    expect(profile.joined, '1403/05/02');
    expect(profile.gender, 'زن');
    expect(profile.age, '22 سال');
    expect(profile.education, 'درج نشده است');
    expect(profile.signature, 'سلام دوستان');
    expect(profile.lastPage, 2);
    final topic = profile.topics.single;
    expect(topic.id, 18997137);
    expect(topic.path, '/discussion/topic/18997137/baby-check');
    expect(topic.title, 'بیبی چک هاله دار');
    expect(topic.dateLabel, '1405/08/08');
    expect(topic.timeLabel, '13:19:36');
    expect(topic.replyCount, 3);
    expect(
      profilePathFromHtml(fixture('profile.html')),
      '/user/discussion/0bfb9576-0682-4a63-a1cb-0dca1ec7a5c0/julia',
    );
  });

  test('sign-in error uses the site message', () {
    final html = fixture('sign_in_error.html');
    expect(signInError(html), 'نام کاربری یا کلمه عبور خود را اشتباه وارد کرده اید.');
    expect(signInError('<html><body>ورود</body></html>'), isNull);
    expect(tokenForAction(html, '/imen/signin', requiredField: 'ShowCaptcha'), 'token-signin');
  });

  test('topic and reply form bodies include the antiforgery token', () {
    final html = fixture('compose_forms.html');
    final topicToken = tokenForAction(html, '/discussion/forum/createtopic');
    final replyToken = tokenForAction(html, '/discussion/create');
    expect(topicToken, 'token-topic');
    expect(replyToken, 'token-reply');

    expect(
      newTopicFields(
        subject: '  عنوان  ',
        message: 'متن تاپیک',
        categoryId: 3,
        forumId: 11,
        token: topicToken!,
      ),
      {
        'Subject': 'عنوان',
        'Message': '<p>متن تاپیک</p>',
        'CategoryId': '3',
        'ForumId': '11',
        '__RequestVerificationToken': 'token-topic',
      },
    );

    final quoted = replyQuote('427624125', plainFromHtml('<p>سلام <strong>دوستان</strong></p>'));
    expect(
      replyFields(topicId: 19007059, message: '$quotedادامه', token: replyToken!),
      {
        'TopicId': '19007059',
        'Message': '<p>[QUOTE=427624125]سلام دوستان[/QUOTE]</p><p>ادامه</p>',
        '__RequestVerificationToken': 'token-reply',
      },
    );
    expect(replyQuote('9', 'ا' * 120), startsWith('[QUOTE=9]'));
    expect(replyQuote('9', 'ا' * 120), endsWith(' ...[/QUOTE]\n'));

    expect(parseTopicPage(html).closed, isTrue);
    final profileForm = parseProfileCompleteForm(html);
    expect(profileForm?.action, '/user/complete');
    expect(profileForm?.fields.map((field) => field.name), containsAll(['Nickname', '__RequestVerificationToken']));

    final board = parseBoardPage(html);
    expect(board.categoryId, 3);
    expect(board.forumId, 11);
  });

  test('set-cookie headers keep both session cookies', () {
    final cookies = <String, String>{};
    storeSetCookieHeader(
      cookies,
      'nn=one; path=/, .ninis=two; expires=Sun, 01 Nov 2026 06:39:14 GMT; path=/',
    );
    expect(cookies['nn'], 'one');
    expect(cookies['.ninis'], 'two');
    expect(iranMobile('۰۹۳۶۰۳۶۷۰۳۱'), '+989360367031');
  });

  test('account menu keeps the site order and the activity heading', () {
    final shell = parseAccountShell(fixture('account_menu.html'));

    expect(shell.name, 'نرگس');
    expect(shell.avatarUrl, contains('/avatar.png'));
    expect(shell.joined, '1405/08/09');
    expect(shell.publicPath, '/user/abc/narges');
    expect(
      shell.entries.map((entry) => entry.title),
      [
        'پروفایل من',
        'داشبورد',
        'اطلاعات کاربری',
        'پیام های من',
        'دوستان من',
        'اعلانات',
        'فعالیت های من در نی نی سایت',
        'تبادل نظر من',
        'کلینیک من',
        'ویدیوهای من',
        'عکس های من',
      ],
    );
    expect(shell.entries[6].isHeading, isTrue);
    expect(accountSection('/profile/setting'), 'settings');
    expect(accountSection('/profile'), 'dashboard');
  });

  test('dashboard counts and a message list use the account payloads', () {
    final counts = parseForumWall(
      jsonDecode(
        '{"TotalPostCount":1,"TotalTopicCount":2,"CreatedNewPostCount":3,"FavoriteNewPostCount":4,"PostedNewPostCount":5}',
      ),
    );
    expect(counts.map((line) => line.value), [1, 2, 3, 4, 5]);

    final messages = parseMessages(
      jsonDecode(
        '{"receivedMessages":[{"ConversationId":4,"Subject":"سلام","Nickname":"مریم","Readed":0,"ConversationUrl":"/profile/conversation/4","Day":"امروز","TimeOfDay":"12:00"}],"totalCount":1}',
      ),
      sent: false,
    );
    final message = messages.records.single;
    expect(message.id, 4);
    expect(message.title, 'سلام');
    expect(message.unread, isTrue);
    expect(message.path, '/profile/conversation/4');
    expect(messages.total, 1);
  });

  test('new message form keeps the recipient search and the message fields', () {
    final draft = parseMessageDraft(fixture('account_message_form.html'));

    expect(draft?.searchUrl, '/profile/conversation/search');
    expect(draft?.form.action, '/profile/conversation/send');
    expect(
      draft?.form.fields.map((field) => field.name),
      containsAll(['UserIds', 'Subject', 'Message', '__RequestVerificationToken']),
    );
    expect(draft?.form.fields.first.label, 'دریافت کننده');
  });
}
