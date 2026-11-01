import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../account_models.dart';
import '../nini_scope.dart';
import '../widgets/account_widgets.dart';
import '../widgets/status_views.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<CountLine> _forum = const [];
  List<CountLine> _clinic = const [];
  List<AccountRecord> _messages = const [];
  List<AccountRecord> _requests = const [];
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
    final api = NiniScope.of(context).account;
    try {
      final results = await Future.wait<Object?>([
        _optional(api.forumWall()),
        _optional(api.clinicWall()),
        _optional(api.messages(sent: false, offset: 0, pageSize: 3)),
        _optional(api.friendRequests(sent: false, offset: 0, pageSize: 3)),
      ]);
      if (!mounted) return;
      if (results.every((item) => item == null)) {
        setState(() {
          _loading = false;
          _error = 'داشبورد بارگذاری نشد.';
        });
        return;
      }
      setState(() {
        _forum = results[0] as List<CountLine>? ?? const [];
        _clinic = results[1] as List<CountLine>? ?? const [];
        _messages = (results[2] as AccountSlice?)?.records ?? const [];
        _requests = (results[3] as AccountSlice?)?.records ?? const [];
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

  Future<void> _friend(Future<void> Function() action) async {
    try {
      await action();
      if (mounted) await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('داشبورد')),
      body: _loading
          ? const LoadingState()
          : _error != null
          ? ErrorState(onRetry: _load)
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  _CountBlock(title: 'تبادل نظر', lines: _forum, onOpen: () => context.push('/account/forum')),
                  _CountBlock(title: 'کلینیک', lines: _clinic, onOpen: () => context.push('/account/clinic')),
                  _Preview(
                    title: 'پیام های من',
                    records: _messages,
                    empty: 'پیامی ندارید.',
                    onOpen: () => context.push('/account/messages'),
                  ),
                  Text('درخواست های دوستی', style: Theme.of(context).textTheme.titleMedium),
                  if (_requests.isEmpty)
                    const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('درخواستی ندارید.'))
                  else
                    for (final request in _requests)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(request.title),
                        subtitle: request.subtitle == null ? null : Text(request.subtitle!),
                        trailing: request.id == null
                            ? null
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextButton(
                                    onPressed: () => _friend(() => NiniScope.of(context).account.acceptFriend(request.id!)),
                                    child: const Text('پذیرش'),
                                  ),
                                  TextButton(
                                    onPressed: () => _friend(() => NiniScope.of(context).account.rejectFriend(request.id!)),
                                    child: const Text('رد کردن'),
                                  ),
                                ],
                              ),
                      ),
                ],
              ),
            ),
    );
  }
}

class _CountBlock extends StatelessWidget {
  const _CountBlock({required this.title, required this.lines, required this.onOpen});

  final String title;
  final List<CountLine> lines;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
            TextButton(onPressed: onOpen, child: const Text('مشاهده همه')),
          ],
        ),
        for (final line in lines)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text('${line.label}: ${line.value}'),
          ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({required this.title, required this.records, required this.empty, required this.onOpen});

  final String title;
  final List<AccountRecord> records;
  final String empty;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
            TextButton(onPressed: onOpen, child: const Text('مشاهده همه')),
          ],
        ),
        if (records.isEmpty)
          Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(empty))
        else
          for (final record in records)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(record.title, style: record.unread ? const TextStyle(fontWeight: FontWeight.w700) : null),
              subtitle: record.subtitle == null || record.subtitle!.isEmpty ? null : Text(record.subtitle!),
              onTap: record.path == null ? null : () => openAccountTarget(context, record.path!, title: record.title),
            ),
        const SizedBox(height: 8),
      ],
    );
  }
}

Future<T?> _optional<T>(Future<T> future) async {
  try {
    return await future;
  } catch (_) {
    return null;
  }
}
