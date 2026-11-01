import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
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

  test('the first line of a message becomes the subject', () {
    expect(messageSubject('سلام\nحالت چطوره'), 'سلام');
    expect(messageSubject('  '), 'گفتگو');
    expect(messageSubject('ا' * 140), 'ا' * 100);
  });
}
