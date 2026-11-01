import 'package:flutter/material.dart';

import '../account_models.dart';
import '../nini_scope.dart';
import '../widgets/account_widgets.dart';
import '../widgets/status_views.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  NoticePage? _page;
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
      final page = await NiniScope.of(context).account.notifications();
      if (!mounted) return;
      setState(() {
        _page = page;
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

  Future<void> _act(AccountRecord record) async {
    final action = record.action ?? _page?.deleteUrl;
    if (action == null) return;
    try {
      await NiniScope.of(context).account.postFields(action, record.fields);
      if (mounted) await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final records = _page?.records ?? const <AccountRecord>[];
    return Scaffold(
      appBar: AppBar(title: const Text('اعلانات')),
      body: _loading
          ? const LoadingState()
          : _error != null
          ? ErrorState(onRetry: _load)
          : records.isEmpty
          ? const EmptyState(message: 'اعلانی نیست.')
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: records.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final record = records[index];
                  return ListTile(
                    title: Text(record.title),
                    onTap: record.path == null ? null : () => openAccountTarget(context, record.path!, title: record.title),
                    trailing: record.action == null && record.fields.isEmpty
                        ? null
                        : TextButton(onPressed: () => _act(record), child: const Text('حذف')),
                  );
                },
              ),
            ),
    );
  }
}
