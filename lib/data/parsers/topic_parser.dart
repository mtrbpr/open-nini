import 'package:html/dom.dart';

import '../../models.dart';
import 'html_utils.dart';

TopicPage parseTopicPage(String html, {int page = 1}) {
  final document = parseDocument(html);
  final title = collapseSpace(document.querySelector('h1.topic-title')?.text ?? '');
  final views = firstInt(
    document.querySelector('meta[itemprop="userInteractionCount"]')?.attributes['content'],
  );
  final posts = <Post>[];
  final original = document.querySelector('article#topic');
  if (original != null && !isAd(original)) {
    final post = _postFromArticle(original, isOriginal: true);
    if (post != null) posts.add(post);
  }
  for (final article in document.querySelectorAll('article')) {
    if (!article.id.startsWith('post-') || isAd(article)) continue;
    final post = _postFromArticle(article, isOriginal: false);
    if (post != null) posts.add(post);
  }
  return TopicPage(
    title: title,
    views: views,
    posts: posts,
    page: page,
    lastPage: lastPageOf(document),
  );
}

Post? _postFromArticle(Element article, {required bool isOriginal}) {
  final quote = article.querySelector('.topic-post__quotation .reply-message');
  final quotedHtml = sanitizePostHtml(quote);
  final body = sanitizePostHtml(article.querySelector('.post-message'));
  final avatar = article.querySelector('img.avatar');
  if (body.isEmpty && quotedHtml.isEmpty && !isOriginal) return null;
  return Post(
    id: article.id,
    author: elementText(article.querySelector('span[itemprop="name"]')) ?? 'ناشناس',
    avatarUrl: avatar == null ? null : imageSource(avatar),
    html: body,
    quotedHtml: quotedHtml.isEmpty ? null : quotedHtml,
    replyToId: quote?.attributes['data-id'],
    publishedAt: publishedAt(article),
    dateLabel: elementText(article.querySelector('.date')),
    timeLabel: elementText(article.querySelector('.time')),
    isOriginal: isOriginal,
  );
}
