import 'package:flutter/material.dart';

import '../data/dates.dart';
import '../models.dart';
import '../nini_scope.dart';
import '../widgets/author_avatar.dart';
import '../widgets/paged_list.dart';
import '../widgets/post_body.dart';

class TopicScreen extends StatefulWidget {
  const TopicScreen({required this.id, required this.title, required this.path, super.key});

  final int id;
  final String title;
  final String path;

  @override
  State<TopicScreen> createState() => _TopicScreenState();
}

class _TopicScreenState extends State<TopicScreen> {
  String? _title;

  @override
  Widget build(BuildContext context) {
    final title = (_title == null || _title!.isEmpty) ? widget.title : _title!;
    return Scaffold(
      appBar: AppBar(
        title: Text(title.isEmpty ? 'تاپیک' : title, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: PagedList<Post>(
        emptyMessage: 'پستی در این تاپیک نیست.',
        idOf: (post) => post.id,
        load: (page) async {
          final result = await NiniScope.of(context).fetchTopic(widget.path, page: page);
          return PageSlice(
            items: result.posts,
            lastPage: result.lastPage,
            title: result.title,
          );
        },
        onLoaded: (slice) {
          final loaded = slice.title;
          if (loaded != null && loaded.isNotEmpty && loaded != _title && mounted) {
            setState(() => _title = loaded);
          }
        },
        itemBuilder: (context, post) => _PostCard(post: post),
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final when = displayPostDate(post.publishedAt, post.dateLabel, post.timeLabel);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AuthorAvatar(url: post.avatarUrl),
                const SizedBox(width: 10),
                Expanded(child: Text(post.author, style: theme.textTheme.titleSmall)),
                if (when.isNotEmpty)
                  Text(
                    when,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (post.quotedHtml != null) QuoteBlock(html: post.quotedHtml!),
            PostBody(html: post.html),
          ],
        ),
      ),
    );
  }
}
