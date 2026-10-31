import 'package:flutter/material.dart';

import '../models.dart';
import '../nini_scope.dart';
import '../router.dart';
import '../widgets/paged_list.dart';

class BoardScreen extends StatefulWidget {
  const BoardScreen({required this.id, required this.name, required this.path, super.key});

  final int id;
  final String name;
  final String path;

  @override
  State<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends State<BoardScreen> {
  String? _title;

  @override
  Widget build(BuildContext context) {
    final title = (_title == null || _title!.isEmpty) ? widget.name : _title!;
    return Scaffold(
      appBar: AppBar(
        title: Text(title.isEmpty ? 'تالار' : title, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: PagedList<ThreadSummary>(
        emptyMessage: 'تاپیکی در این تالار نیست.',
        idOf: (thread) => '${thread.id}',
        load: (page) async {
          final result = await NiniScope.of(context).fetchBoard(widget.path, page: page);
          return PageSlice(
            items: result.threads,
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
        itemBuilder: (context, thread) => _ThreadTile(thread: thread),
      ),
    );
  }
}

class _ThreadTile extends StatelessWidget {
  const _ThreadTile({required this.thread});

  final ThreadSummary thread;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final meta = [
      if (thread.author != null) thread.author!,
      '${thread.replyCount} پاسخ',
      if (thread.lastWhen != null) thread.lastWhen!,
    ].join(' · ');
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => openTopic(
          context,
          id: thread.id,
          path: thread.path,
          title: thread.title,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (thread.pinned)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    'سنجاق‌شده',
                    style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.primary),
                  ),
                ),
              Text(thread.title, style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                meta,
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              if (thread.lastReply != null) ...[
                const SizedBox(height: 8),
                Text(
                  'پاسخ آخر: ${thread.lastReply}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
