import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:open_nini/data/dates.dart';
import 'package:open_nini/data/nini_client.dart';
import 'package:open_nini/data/parsers/parsers.dart';

void main() {
  String fixture(String name) => File('test/fixtures/$name').readAsStringSync();

  test('discussion index groups boards and reads the latest thread', () {
    final index = parseDiscussionIndex(fixture('discussion_index.html'));
    final groups = index.groups;

    expect(groups, hasLength(1));
    expect(groups.single.id, 3);
    expect(groups.single.name, 'بارداری و زایمان');
    expect(groups.single.icon, 'iconbirth');
    expect(groups.single.path, '/discussion/3/%D8%A8%D8%A7%D8%B1%D8%AF%D8%A7%D8%B1%DB%8C');
    final board = groups.single.boards.single;
    expect(board.id, 6);
    expect(board.name, 'رشد و تکامل جنین');
    expect(board.path, '/discussion/forum/6/%D8%B1%D8%B4%D8%AF');
    expect(board.topicCount, 180098);
    expect(board.latestTitle, 'چند هفته برم سونو');
    expect(board.latestAuthor, 'mommjoooonnn');
    expect(board.latestWhen, 'امروز 07:04');

    expect(index.highlights.map((section) => section.title), [
      'جدیدترین تاپیک های 2 روز گذشته',
      'تاپیک های به روز شده',
      'پربازدیدترین تاپیک های امروز',
      'داغ ترین های تاپیک های 2 روز گذشته',
      'داغ ترین های تاپیک های امروز',
    ]);
    final newest = index.highlights.first.topics.single;
    expect(newest.id, 19007059);
    expect(newest.path, '/discussion/topic/19007059/shoes');
    expect(newest.subtitle, 'نچرال · 3 ثانیه پیش');
    final updated = index.highlights[1].topics.single;
    expect(updated.path, '/discussion/topic/19007046/feel');
    expect(updated.subtitle, 'من میترسم پشیمون بشم · 1 دقیقه پیش');
    expect(index.highlights[2].topics.single.subtitle, 'sisi_ · 10 ساعت پیش');
  });

  test('board page reads one thread and the last pagination page', () {
    final page = parseBoardPage(fixture('board.html'));

    expect(page.title, 'رشد و تکامل جنین و سیر بارداری');
    expect(page.threadCount, 180098);
    expect(page.lastPage, 6004);
    expect(page.threads, hasLength(1));
    final thread = page.threads.single;
    expect(thread.id, 19001240);
    expect(thread.title, 'چند هفته برم سونو ان تی خوبه');
    expect(thread.path, '/discussion/topic/19001240/sono');
    expect(thread.author, 'mommjoooonnn');
    expect(thread.replyCount, 1);
    expect(thread.pinned, isTrue);
    expect(thread.lastReply, 'همون ۱۲ هفته و ۲،۳ روز برو');
    expect(thread.lastWhen, 'امروز 07:04');
  });

  test('topic page keeps the quote and image and drops ads', () {
    final page = parseTopicPage(fixture('topic.html'));

    expect(page.title, 'واکسن آنفلانزا بارداری');
    expect(page.views, 48);
    expect(page.lastPage, 3);
    expect(page.posts.map((post) => post.id), ['topic', 'post-427526796']);

    final original = page.posts.first;
    expect(original.author, 'maneli1368');
    expect(
      original.avatarUrl,
      'https://as3.ninisite.com/statics/profile/default/woman2.svg?width=80&height=85',
    );
    expect(original.isOriginal, isTrue);
    expect(original.html, contains('<strong>دوستان</strong>'));
    expect(original.html, contains('https://as3.ninisite.com/uploads/vaccine.jpg'));
    expect(original.html, isNot(contains('blank-loading')));
    expect(original.html, isNot(contains('alert')));
    expect(original.publishedAt, DateTime(2026, 10, 31, 1, 32));

    final reply = page.posts.last;
    expect(reply.author, 'پرنسس00');
    expect(reply.avatarUrl, isNull);
    expect(reply.replyToId, '427526471');
    expect(reply.quotedHtml, contains('نه نزن عوارضش زیاده'));
    expect(reply.quotedHtml, isNot(contains('fa-caret')));
    expect(reply.html, contains('کزاز چند هفته میزنید؟'));
    expect(
      reply.html,
      contains('href="https://www.ninisite.com/discussion/topic/18688306/slug"'),
    );
    expect(parseTopicLink('https://www.ninisite.com/discussion/topic/18688306/slug')?.id, 18688306);
    expect(parseTopicLink('https://example.com/discussion/topic/1/x'), isNull);
  });

  test('jalali labels use today and yesterday', () {
    final published = DateTime(2026, 10, 5, 10, 11, 18);
    expect(formatPostDate(published, now: DateTime(2026, 10, 5, 18)), 'امروز 10:11');
    expect(formatPostDate(published, now: DateTime(2026, 10, 6, 8)), 'دیروز 10:11');
    expect(formatPostDate(published, now: DateTime(2026, 10, 31)), '1405/07/13 10:11');
  });

  test('page links append the page query', () {
    expect(
      niniPageUri('/discussion/forum/6/slug', 1).toString(),
      'https://www.ninisite.com/discussion/forum/6/slug',
    );
    expect(niniPageUri('/discussion/topic/9/slug', 2).queryParameters['page'], '2');
  });
}
