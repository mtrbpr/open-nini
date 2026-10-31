class BoardGroup {
  const BoardGroup({
    required this.id,
    required this.name,
    required this.path,
    required this.boards,
    this.icon,
  });

  final int id;
  final String name;
  final String path;
  final String? icon;
  final List<Board> boards;
}

class Board {
  const Board({
    required this.id,
    required this.name,
    required this.path,
    required this.topicCount,
    this.latestTitle,
    this.latestAuthor,
    this.latestWhen,
  });

  final int id;
  final String name;
  final String path;
  final int topicCount;
  final String? latestTitle;
  final String? latestAuthor;
  final String? latestWhen;
}

class BoardPage {
  const BoardPage({
    required this.title,
    required this.threadCount,
    required this.threads,
    required this.page,
    required this.lastPage,
  });

  final String title;
  final int? threadCount;
  final List<ThreadSummary> threads;
  final int page;
  final int lastPage;
}

class ThreadSummary {
  const ThreadSummary({
    required this.id,
    required this.title,
    required this.path,
    required this.replyCount,
    required this.pinned,
    this.author,
    this.lastReply,
    this.lastWhen,
  });

  final int id;
  final String title;
  final String path;
  final String? author;
  final int replyCount;
  final String? lastReply;
  final String? lastWhen;
  final bool pinned;
}

class TopicPage {
  const TopicPage({
    required this.title,
    required this.views,
    required this.posts,
    required this.page,
    required this.lastPage,
  });

  final String title;
  final int? views;
  final List<Post> posts;
  final int page;
  final int lastPage;
}

class Post {
  const Post({
    required this.id,
    required this.author,
    required this.html,
    required this.isOriginal,
    this.quotedHtml,
    this.replyToId,
    this.publishedAt,
    this.dateLabel,
    this.timeLabel,
  });

  final String id;
  final String author;
  final String html;
  final String? quotedHtml;
  final String? replyToId;
  final DateTime? publishedAt;
  final String? dateLabel;
  final String? timeLabel;
  final bool isOriginal;
}

class TopicLink {
  const TopicLink({required this.id, required this.path});

  final int id;
  final String path;
}
