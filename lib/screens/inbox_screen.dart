import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../account_models.dart';
import '../nini_scope.dart';
import '../router.dart';
import '../widgets/author_avatar.dart';
import '../widgets/status_views.dart';
import 'app_shell.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  List<InboxPerson>? _people;
  var _loading = false;
  var _failed = false;
  var _tick = -1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load() async {
    if (!mounted) return;
    if (!NiniScope.of(context).signedIn) {
      setState(() {
        _people = const [];
        _failed = false;
        _loading = false;
      });
      return;
    }
    if (_loading) return;
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final people = await NiniScope.of(context).account.inbox();
      if (!mounted) return;
      setState(() {
        _people = people;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _failed = true;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tick = InboxSignal.of(context);
    if (tick != _tick) {
      final previous = _tick;
      _tick = tick;
      if (previous >= 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _load();
        });
      }
    }
    final signedIn = NiniScope.of(context).signedIn;
    return Scaffold(
      appBar: AppBar(
        title: const Text('پیام‌ها'),
        actions: [
          if (signedIn)
            IconButton(
              tooltip: 'گفتگوی جدید',
              onPressed: () async {
                await context.push('/people');
                if (mounted) _load();
              },
              icon: const Icon(Icons.person_add_alt),
            ),
        ],
      ),
      body: !signedIn
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('برای دیدن پیام‌ها وارد شوید.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
                    const SizedBox(height: 16),
                    FilledButton(onPressed: () => context.push('/sign-in'), child: const Text('ورود')),
                  ],
                ),
              ),
            )
          : _body(),
    );
  }

  Widget _body() {
    final people = _people;
    if (_failed && people == null) return ErrorState(onRetry: _load);
    if (people == null || (_loading && people.isEmpty)) return const LoadingState();
    return RefreshIndicator(
      onRefresh: _load,
      child: people.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 120),
                EmptyState(message: 'پیامی ندارید.'),
              ],
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: people.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final person = people[index];
                return ListTile(
                  leading: AuthorAvatar(url: person.avatarUrl),
                  title: Text(person.name, style: person.unread ? const TextStyle(fontWeight: FontWeight.w700) : null),
                  subtitle: Text(person.subject, maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (person.when != null)
                        Text(person.when!, style: Theme.of(context).textTheme.bodySmall),
                      if (person.unread)
                        Container(
                          margin: const EdgeInsets.only(top: 6),
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, shape: BoxShape.circle),
                        ),
                    ],
                  ),
                  onTap: () async {
                    await openChat(context, name: person.name, avatarUrl: person.avatarUrl);
                    if (mounted) _load();
                  },
                );
              },
            ),
    );
  }
}
