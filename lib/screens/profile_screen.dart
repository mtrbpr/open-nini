import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/parsers/chat_parser.dart';
import '../models.dart';
import '../nini_scope.dart';
import '../router.dart';
import '../widgets/author_avatar.dart';
import '../widgets/paged_list.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({this.path, super.key});

  final String? path;

  @override
  Widget build(BuildContext context) {
    final repository = NiniScope.of(context);
    final profilePath = path ?? repository.profilePath;
    final own = path == null || path == repository.profilePath;
    return Scaffold(
      appBar: AppBar(
        title: const Text('نمایه'),
        actions: [
          if (own && repository.signedIn)
            TextButton(
              onPressed: () async {
                await repository.signOut();
                if (context.mounted) context.pop();
              },
              child: const Text('خروج'),
            ),
        ],
      ),
      body: profilePath == null
          ? const Center(child: Text('برای دیدن نمایه وارد شوید.'))
          : PagedList<ProfileTopic>(
              emptyMessage: 'موضوعی در این نمایه نیست.',
              idOf: (topic) => '${topic.id}',
              load: (page) async {
                final profile = await repository.fetchProfile(profilePath, page: page);
                return PageSlice(
                  items: profile.topics,
                  lastPage: profile.lastPage,
                  title: profile.name,
                  header: _ProfileHeader(
                    profile: profile,
                    path: profilePath,
                    signedIn: repository.signedIn,
                    own: own,
                  ),
                );
              },
              itemBuilder: (context, topic) => _ProfileTopicTile(topic: topic),
            ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.profile,
    required this.path,
    required this.signedIn,
    required this.own,
  });

  final UserProfile profile;
  final String? path;
  final bool signedIn;
  final bool own;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rows = <(String, String?)>[
      ('عضویت', profile.joined),
      ('جنسیت', profile.gender),
      ('سن', profile.age),
      ('تحصیلات', profile.education),
      ('امضا', profile.signature),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        children: [
          AuthorAvatar(url: profile.avatarUrl, size: 72),
          const SizedBox(height: 12),
          Text(profile.name, style: theme.textTheme.titleLarge),
          if (signedIn && !own && path != null && userGuid(path) != null) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              alignment: WrapAlignment.center,
              children: [
                FilledButton(
                  onPressed: () => openChat(context, name: profile.name, avatarUrl: profile.avatarUrl, userPath: path),
                  child: const Text('گفتگو'),
                ),
                OutlinedButton(onPressed: () => _invite(context, path!), child: const Text('دعوت به دوستی')),
              ],
            ),
          ],
          for (final row in rows)
            if (row.$2 != null && row.$2!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('${row.$1}: ${row.$2}', textAlign: TextAlign.center),
              ),
        ],
      ),
    );
  }
}

Future<void> _invite(BuildContext context, String path) async {
  try {
    final failure = await NiniScope.of(context).account.inviteFriend(path);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(failure ?? 'درخواست دوستی فرستاده شد.')),
    );
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
  }
}

class _ProfileTopicTile extends StatelessWidget {
  const _ProfileTopicTile({required this.topic});

  final ProfileTopic topic;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final meta = [
      if (topic.dateLabel != null) topic.dateLabel!,
      if (topic.timeLabel != null) topic.timeLabel!,
      if (topic.replyCount != null) '${topic.replyCount} پست',
    ].join(' · ');
    return Card(
      child: ListTile(
        title: Text(topic.title),
        subtitle: meta.isEmpty ? null : Text(meta, style: theme.textTheme.bodySmall),
        onTap: () => openTopic(context, id: topic.id, path: topic.path, title: topic.title),
      ),
    );
  }
}
