class DiscussionIndex {
  const DiscussionIndex({required this.groups, required this.highlights});

  final List<BoardGroup> groups;
  final List<TopicSection> highlights;
}

class TopicSection {
  const TopicSection({required this.title, required this.topics});

  final String title;
  final List<HighlightTopic> topics;
}

class HighlightTopic {
  const HighlightTopic({
    required this.id,
    required this.title,
    required this.path,
    this.subtitle,
  });

  final int id;
  final String title;
  final String path;
  final String? subtitle;
}

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
    this.categoryId,
    this.forumId,
  });

  final String title;
  final int? threadCount;
  final List<ThreadSummary> threads;
  final int page;
  final int lastPage;
  final int? categoryId;
  final int? forumId;
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
    this.closed = false,
  });

  final String title;
  final int? views;
  final List<Post> posts;
  final int page;
  final int lastPage;
  final bool closed;
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
    this.avatarUrl,
    this.authorPath,
    this.quoteId,
  });

  final String id;
  final String author;
  final String? authorPath;
  final String? quoteId;
  final String html;
  final String? quotedHtml;
  final String? replyToId;
  final DateTime? publishedAt;
  final String? avatarUrl;
  final String? dateLabel;
  final String? timeLabel;
  final bool isOriginal;
}

class TopicLink {
  const TopicLink({required this.id, required this.path});

  final int id;
  final String path;
}

class UserProfile {
  const UserProfile({
    required this.name,
    required this.topics,
    required this.page,
    required this.lastPage,
    this.avatarUrl,
    this.joined,
    this.gender,
    this.age,
    this.education,
    this.signature,
  });

  final String name;
  final String? avatarUrl;
  final String? joined;
  final String? gender;
  final String? age;
  final String? education;
  final String? signature;
  final List<ProfileTopic> topics;
  final int page;
  final int lastPage;
}

class ProfileTopic {
  const ProfileTopic({
    required this.id,
    required this.title,
    required this.path,
    this.dateLabel,
    this.timeLabel,
    this.replyCount,
  });

  final int id;
  final String title;
  final String path;
  final String? dateLabel;
  final String? timeLabel;
  final int? replyCount;
}

class ForumCategory {
  const ForumCategory({required this.id, required this.name, required this.forums});

  final int id;
  final String name;
  final List<ForumOption> forums;
}

class ForumOption {
  const ForumOption({required this.id, required this.name});

  final int id;
  final String name;
}
