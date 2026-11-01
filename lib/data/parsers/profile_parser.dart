import 'package:html/dom.dart';

import '../../models.dart';
import 'html_utils.dart';

UserProfile parseProfile(String html, {int page = 1}) {
  final document = parseDocument(html);
  final about = document.querySelector('.about');
  final avatar = document.querySelector('.profile__img img');
  return UserProfile(
    name: elementText(document.querySelector('.profile__name')) ?? '',
    avatarUrl: avatar == null ? null : imageSource(avatar),
    joined: _detail(about, 'iconcalender', strip: 'عضویت'),
    gender: _gender(about),
    age: _detail(about, 'iconbirthday-stroke'),
    education: _detail(about, 'iconeducation'),
    signature: _detail(about, 'iconsignature'),
    topics: document.querySelectorAll('.forum-row').map(_topic).whereType<ProfileTopic>().toList(),
    page: page,
    lastPage: lastPageOf(document),
  );
}

ProfileTopic? _topic(Element row) {
  final link = row.querySelector('a.forum-subject');
  final href = link?.attributes['href'];
  if (href == null) return null;
  final parsed = parseTopicLink(href);
  final title = elementText(link);
  if (parsed == null || title == null) return null;
  return ProfileTopic(
    id: parsed.id,
    title: title,
    path: parsed.path,
    dateLabel: elementText(row.querySelector('.date')),
    timeLabel: elementText(row.querySelector('.time')),
    replyCount: firstInt(row.querySelector('.comment-title-moblie-up')?.text) ??
        firstInt(row.querySelector('.comment-title-moblie-down')?.text),
  );
}

String? _gender(Element? about) {
  return _detail(about, 'iconwoman') ?? _detail(about, 'iconman');
}

String? _detail(Element? about, String icon, {String? strip}) {
  if (about == null) return null;
  final node = about.querySelector('i.$icon');
  final text = elementText(node?.parent);
  if (text == null) return null;
  if (strip == null) return text;
  return text.replaceFirst(RegExp('^$strip\\s*:?\\s*'), '').trim();
}
