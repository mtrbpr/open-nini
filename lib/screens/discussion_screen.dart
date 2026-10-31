import 'package:flutter/material.dart';

import '../models.dart';
import '../nini_scope.dart';
import '../router.dart';
import '../widgets/status_views.dart';

class DiscussionScreen extends StatefulWidget {
  const DiscussionScreen({required this.id, required this.name, super.key});

  final int id;
  final String name;

  @override
  State<DiscussionScreen> createState() => _DiscussionScreenState();
}

class _DiscussionScreenState extends State<DiscussionScreen> {
  Future<BoardGroup?>? _group;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _group ??= _load();
  }

  Future<BoardGroup?> _load({bool refresh = false}) async {
    final groups = await NiniScope.of(context).fetchIndex(refresh: refresh);
    for (final group in groups) {
      if (group.id == widget.id) return group;
    }
    return null;
  }

  Future<void> _reload() async {
    final future = _load(refresh: true);
    setState(() => _group = future);
    try {
      await future;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<BoardGroup?>(
          future: _group,
          builder: (context, snapshot) {
            final name = snapshot.data?.name;
            final title = (name == null || name.isEmpty) ? widget.name : name;
            return Text(
              title.isEmpty ? 'بحث' : title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            );
          },
        ),
      ),
      body: FutureBuilder<BoardGroup?>(
        future: _group,
        builder: (context, snapshot) {
          if (_group == null ||
              (snapshot.connectionState != ConnectionState.done && !snapshot.hasData)) {
            return const LoadingState();
          }
          if (snapshot.hasError) return ErrorState(onRetry: _reload);
          final boards = snapshot.data?.boards ?? const <Board>[];
          if (boards.isEmpty) {
            return const EmptyState(message: 'تالاری پیدا نشد.');
          }
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(top: 8, bottom: 24),
              children: [for (final board in boards) _BoardTile(board: board)],
            ),
          );
        },
      ),
    );
  }
}

class _BoardTile extends StatelessWidget {
  const _BoardTile({required this.board});

  final Board board;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final latest = board.latestTitle;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => openBoard(context, board),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(board.name, style: theme.textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(
                '${board.topicCount} تاپیک',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (latest != null) ...[
                const SizedBox(height: 8),
                Text(
                  latest,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium,
                ),
                if (board.latestAuthor != null || board.latestWhen != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      [
                        if (board.latestAuthor != null) board.latestAuthor!,
                        if (board.latestWhen != null) board.latestWhen!,
                      ].join(' · '),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
