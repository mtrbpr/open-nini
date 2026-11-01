import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../account_models.dart';
import '../nini_scope.dart';
import '../router.dart';
import '../widgets/author_avatar.dart';
import '../widgets/status_views.dart';
import '../data/parsers/account_parser.dart';

class AccountHubScreen extends StatefulWidget {
  const AccountHubScreen({super.key});

  @override
  State<AccountHubScreen> createState() => _AccountHubScreenState();
}

class _AccountHubScreenState extends State<AccountHubScreen> {
  AccountShell? _shell;
  var _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final shell = await NiniScope.of(context).account.shell();
      if (!mounted) return;
      setState(() {
        _shell = shell;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = '$error';
        _loading = false;
      });
    }
  }

  void _open(AccountMenuEntry entry) {
    final path = entry.path;
    if (path == null) return;
    if (path.startsWith('/user/')) {
      openProfile(context, path: path);
      return;
    }
    final section = accountSection(path);
    if (section == 'messages') {
      context.go('/messages');
      return;
    }
    if (section == 'picture') {
      openAccountPage(context, '/profile/profilepicture', title: 'تصویر نمایه');
      return;
    }
    if (section == null) return;
    context.push('/account/$section');
  }

  @override
  Widget build(BuildContext context) {
    final repository = NiniScope.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('نی‌نی‌سایت من'),
        actions: [
          if (repository.signedIn)
            TextButton(
              onPressed: () async {
                await repository.signOut();
                if (context.mounted) context.pop();
              },
              child: const Text('خروج'),
            ),
        ],
      ),
      body: !repository.signedIn
          ? const EmptyState(message: 'برای دیدن نمایه وارد شوید.')
          : _body(),
    );
  }

  Widget _body() {
    if (_loading) return const LoadingState();
    if (_error != null) return ErrorState(onRetry: _load);
    final shell = _shell;
    if (shell == null) return const EmptyState(message: 'موردی پیدا نشد.');
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Column(
            children: [
              GestureDetector(
                onTap: () => openAccountPage(context, '/profile/profilepicture', title: 'تصویر نمایه'),
                child: AuthorAvatar(url: shell.avatarUrl, size: 72),
              ),
              const SizedBox(height: 12),
              Text(shell.name, style: Theme.of(context).textTheme.titleLarge),
              if (shell.joined != null) Text('عضویت: ${shell.joined}'),
            ],
          ),
        ),
        for (final entry in shell.entries)
          entry.isHeading
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Text(entry.title, style: Theme.of(context).textTheme.titleMedium),
                )
              : ListTile(
                  title: Text(entry.title),
                  onTap: () => _open(entry),
                ),
      ],
    );
  }
}
