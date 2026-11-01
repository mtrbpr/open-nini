import '../models.dart';
import 'nini_client.dart';
import 'parsers/parsers.dart';

class NiniRepository {
  NiniRepository({NiniClient? client}) : _client = client ?? NiniClient();

  final NiniClient _client;
  DiscussionIndex? _index;

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
    );
  }
}
