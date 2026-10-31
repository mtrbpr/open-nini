import 'package:flutter/material.dart';

import '../discussion_icons.dart';
import '../models.dart';
import '../nini_scope.dart';
import '../router.dart';
import '../widgets/status_views.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<List<BoardGroup>>? _groups;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _groups ??= NiniScope.of(context).fetchIndex();
  }

  Future<void> _reload() async {
    final future = NiniScope.of(context).fetchIndex(refresh: true);
    setState(() => _groups = future);
    try {
      await future;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('nini')),
      body: FutureBuilder<List<BoardGroup>>(
        future: _groups ?? Future.value(const <BoardGroup>[]),
        builder: (context, snapshot) {
          if (_groups == null ||
              (snapshot.connectionState != ConnectionState.done && !snapshot.hasData)) {
            return const LoadingState();
          }
          if (snapshot.hasError) return ErrorState(onRetry: _reload);
          final groups = snapshot.data ?? const <BoardGroup>[];
          if (groups.isEmpty) {
            return const EmptyState(message: 'بحثی پیدا نشد.');
          }
          return RefreshIndicator(
            onRefresh: _reload,
            child: GridView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.92,
              ),
              itemCount: groups.length,
              itemBuilder: (context, index) => _DiscussionTile(group: groups[index]),
            ),
          );
        },
      ),
    );
  }
}

class _DiscussionTile extends StatelessWidget {
  const _DiscussionTile({required this.group});

  final BoardGroup group;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => openDiscussion(context, group),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                discussionIcon(group.icon),
                size: 40,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Text(
                group.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
