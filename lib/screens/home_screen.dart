import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
  Future<DiscussionIndex>? _index;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _index ??= NiniScope.of(context).fetchIndex();
  }

  Future<void> _reload() async {
    final future = NiniScope.of(context).fetchIndex(refresh: true);
    setState(() => _index = future);
    try {
      await future;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final signedIn = NiniScope.of(context).signedIn;
    return Scaffold(
      body: FutureBuilder<DiscussionIndex>(
        future: _index,
        builder: (context, snapshot) {
          if (_index == null ||
              (snapshot.connectionState != ConnectionState.done && !snapshot.hasData)) {
            return _AccountFrame(signedIn: signedIn, child: const LoadingState());
          }
          if (snapshot.hasError || snapshot.data == null) {
            return _AccountFrame(signedIn: signedIn, child: ErrorState(onRetry: _reload));
          }
          final page = snapshot.data!;
          if (page.groups.isEmpty && page.highlights.isEmpty) {
            return _AccountFrame(signedIn: signedIn, child: const EmptyState(message: 'بحثی پیدا نشد.'));
          }
          return RefreshIndicator(
            onRefresh: _reload,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _AccountButton(signedIn: signedIn)),
                if (page.groups.isNotEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.82,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _DiscussionTile(group: page.groups[index]),
                        childCount: page.groups.length,
                      ),
                    ),
                  ),
                for (final section in page.highlights) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
                      child: Text(section.title, style: Theme.of(context).textTheme.titleMedium),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, itemIndex) => _HighlightTile(topic: section.topics[itemIndex]),
                      childCount: section.topics.length,
                    ),
                  ),
                ],
                const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AccountFrame extends StatelessWidget {
  const _AccountFrame({required this.signedIn, required this.child});

  final bool signedIn;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _AccountButton(signedIn: signedIn),
        Expanded(child: child),
      ],
    );
  }
}

class _AccountButton extends StatelessWidget {
  const _AccountButton({required this.signedIn});

  final bool signedIn;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = signedIn ? 'نی‌نی‌سایت من' : 'ورود';
    final screenWidth = MediaQuery.sizeOf(context).width;
    final tileWidth = screenWidth > 48 ? (screenWidth - 48) / 3 : 120.0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 24, 12, 8),
      child: Center(
        child: SizedBox(
          width: tileWidth,
          child: Card(
            margin: EdgeInsets.zero,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => signedIn ? openProfile(context) : context.push('/sign-in'),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      signedIn ? Icons.person : Icons.person_outline,
                      size: 36,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
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
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                discussionIcon(group.icon),
                size: 24,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 8),
              Text(
                group.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HighlightTile extends StatelessWidget {
  const _HighlightTile({required this.topic});

  final HighlightTopic topic;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle = topic.subtitle;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => openTopic(context, id: topic.id, path: topic.path, title: topic.title),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                topic.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
