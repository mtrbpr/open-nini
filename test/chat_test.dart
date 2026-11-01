import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:open_nini/account_models.dart';
import 'package:open_nini/data/parsers/parsers.dart';

void main() {
  String fixture(String name) => File('test/fixtures/$name').readAsStringSync();

  test('a conversation page keeps both sides and the reply form', () {
    final thread = parseConversation(fixture('conversation_thread.html'));

    expect(thread.conversationId, 4);
    expect(thread.replyToken, 'token-reply');
    expect(thread.replyAction, '/profile/conversation/reply');
    expect(thread.deleteMessageUrl, '/profile/conversation/deletemessage');
    expect(thread.messages.map((message) => message.body), ['سلام', 'علی']);
    expect(thread.messages.map((message) => message.mine), [true, false]);
    expect(thread.messages.first.id, 9);
    expect(thread.messages.first.conversationId, 4);
  });

  test('user search reads the nickname, profile path, and avatar', () {
    final people = parsePeople(fixture('user_search.html'));

    expect(people.single.name, 'mesi1980');
    expect(people.single.path, '/user/40e9d093-962e-449b-a006-9a552621d9c9/mesi1980');
    expect(people.single.avatarUrl, 'https://example.com/a.jpg');
    expect(userGuid(people.single.path), '40e9d093-962e-449b-a006-9a552621d9c9');
  });

  test('inbox rows merge threads that belong to one person', () {
    final received = parseMessages(
      jsonDecode(
        '{"receivedMessages":[{"ConversationId":4,"Subject":"سلام","Nickname":"مریم","Readed":0,"ConversationUrl":"/profile/conversation/4","Avatar":"https://example.com/m.jpg","Day":"امروز","TimeOfDay":"12:00"}],"totalCount":1}',
      ),
      sent: false,
    );
    final sent = parseMessages(
      jsonDecode(
        '{"sentMessages":[{"ConversationId":8,"Subject":"بعدی","Nickname":"مریم","Readed":1,"ConversationUrl":"/profile/conversation/8","Avatar":"https://example.com/m.jpg","Day":"دیروز","TimeOfDay":"09:00"}],"totalCount":1}',
      ),
      sent: true,
    );

    final person = groupConversations(received.records, sent.records).single;
    expect(person.name, 'مریم');
    expect(person.subject, 'سلام');
    expect(person.when, 'امروز · 12:00');
    expect(person.unread, isTrue);
    expect(person.replyConversationId, 4);
    expect(person.threads, ['/profile/conversation/4', '/profile/conversation/8']);
  });

  test('a sent request with no messages is one pending row', () {
    const request = AccountRecord(
      title: 'مریم',
      imageUrl: 'https://example.com/m.jpg',
      path: '/user/abc/maryam',
    );

    final people = mergeInbox(const [], const [request], const []);

    expect(people, hasLength(1));
    expect(people.single.pending, isTrue);
    expect(people.single.subject, pendingRequestLabel);
    expect(people.single.userPath, '/user/abc/maryam');
  });

  test('a conversation is not duplicated by a sent request or a friendship', () {
    final conversations = groupConversations(
      parseMessages(
        jsonDecode(
          '{"receivedMessages":[{"ConversationId":4,"Subject":"سلام","Nickname":"مریم","Readed":1,"ConversationUrl":"/profile/conversation/4","Day":"امروز","TimeOfDay":"12:00"}],"totalCount":1}',
        ),
        sent: false,
      ).records,
      const [],
    );
    const request = AccountRecord(title: 'مریم', path: '/user/abc/maryam');
    const friend = AccountRecord(title: 'مریم', path: '/user/abc/maryam');

    final people = mergeInbox(conversations, const [request], const [friend]);

    expect(people, hasLength(1));
    expect(people.single.pending, isFalse);
    expect(people.single.subject, 'سلام');
  });

  test('a friend with no messages stays as a chat that can start', () {
    const friend = AccountRecord(title: 'سارا', path: '/user/def/sara');

    final people = mergeInbox(const [], const [], const [friend]);

    expect(people.single.pending, isFalse);
    expect(people.single.subject, startChatLabel);
    expect(people.single.userPath, '/user/def/sara');
  });

  test('the first line of a message becomes the subject', () {
    expect(messageSubject('سلام\nحالت چطوره'), 'سلام');
    expect(messageSubject('  '), 'گفتگو');
    expect(messageSubject('ا' * 140), 'ا' * 100);
  });
}
