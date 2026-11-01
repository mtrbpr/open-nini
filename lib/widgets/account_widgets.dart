import 'package:flutter/material.dart';

import '../account_models.dart';
import '../data/nini_client.dart';
import '../data/parsers/html_utils.dart';
import '../router.dart';
import 'author_avatar.dart';
import 'status_views.dart';

class AccountButton {
  const AccountButton({required this.label, required this.run, this.confirm});

  final String label;
  final String? confirm;
  final Future<void> Function() run;
}

class AccountTabSpec {
  const AccountTabSpec({required this.label, required this.load, required this.actions});

  final String label;
  final Future<AccountSlice> Function(int offset) load;
  final List<AccountButton> Function(AccountRecord record) actions;
}

class AccountBrowser extends StatefulWidget {
  const AccountBrowser({
    required this.title,
    required this.tabs,
    this.action,
    this.header,
    super.key,
  });

  final String title;
  final List<AccountTabSpec> tabs;
  final Widget? action;
  final Widget? header;

  @override
  State<AccountBrowser> createState() => _AccountBrowserState();
}

class _AccountBrowserState extends State<AccountBrowser> {
  static const _pageSize = 20;

  var _tab = 0;
  var _loading = true;
  var _loadingMore = false;
  var _hasMore = false;
  String? _error;
  final _records = <AccountRecord>[];

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  Future<void> _load({required bool reset}) async {
    if (!reset && (_loadingMore || !_hasMore)) return;
    setState(() {
      if (reset) {
        _error = null;
        if (_records.isEmpty) _loading = true;
      } else {
        _loadingMore = true;
      }
    });
    try {
      final slice = await widget.tabs[_tab].load(reset ? 0 : _records.length);
      if (!mounted) return;
      setState(() {
        if (reset) _records.clear();
        _records.addAll(slice.records);
        _hasMore = slice.records.length >= _pageSize;
        _loading = false;
        _loadingMore = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = '$error';
        _loading = false;
        _loadingMore = false;
      });
    }
  }

  Future<void> _run(AccountButton button) async {
    if (button.confirm != null) {
      final accepted = await confirmAccountAction(context, button.confirm!);
      if (!accepted || !mounted) return;
    }
    try {
      await button.run();
      if (mounted) await _load(reset: true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [if (widget.action != null) widget.action!],
      ),
      body: Column(
        children: [
          if (widget.tabs.length > 1)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  for (var index = 0; index < widget.tabs.length; index++)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(end: 8),
                      child: ChoiceChip(
                        label: Text(widget.tabs[index].label),
                        selected: index == _tab,
                        onSelected: (selected) {
                          if (!selected || index == _tab) return;
                          setState(() {
                            _tab = index;
                            _records.clear();
                            _loading = true;
                            _error = null;
                          });
                          _load(reset: true);
                        },
                      ),
                    ),
                ],
              ),
            ),
          if (widget.header != null) widget.header!,
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _body() {
    if (_loading) return const LoadingState();
    if (_error != null && _records.isEmpty) {
      return ErrorState(onRetry: () => _load(reset: true));
    }
    if (_records.isEmpty) return const EmptyState(message: 'موردی پیدا نشد.');
    return RefreshIndicator(
      onRefresh: () => _load(reset: true),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _records.length + (_hasMore ? 1 : 0),
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          if (index >= _records.length) {
            return TextButton(
              onPressed: _loadingMore ? null : () => _load(reset: false),
              child: Text(_loadingMore ? '...' : 'بیشتر'),
            );
          }
          final record = _records[index];
          final actions = widget.tabs[_tab].actions(record);
          return ListTile(
            leading: record.imageUrl == null ? null : AuthorAvatar(url: record.imageUrl, size: 40),
            title: Text(
              record.title,
              style: record.unread ? const TextStyle(fontWeight: FontWeight.w700) : null,
            ),
            subtitle: record.subtitle == null || record.subtitle!.isEmpty ? null : Text(record.subtitle!),
            onTap: record.path == null ? null : () => openAccountTarget(context, record.path!, title: record.title),
            trailing: actions.isEmpty
                ? null
                : PopupMenuButton<int>(
                    onSelected: (choice) => _run(actions[choice]),
                    itemBuilder: (context) => [
                      for (var choice = 0; choice < actions.length; choice++)
                        PopupMenuItem(value: choice, child: Text(actions[choice].label)),
                    ],
                  ),
          );
        },
      ),
    );
  }
}

Future<bool> confirmAccountAction(BuildContext context, String message) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('انصراف')),
        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('بله')),
      ],
    ),
  );
  return result == true;
}

void openAccountTarget(BuildContext context, String path, {String? title}) {
  final normalized = pathOnly(path);
  final topicId = idFromPath(normalized, 'topic');
  if (topicId != null) {
    openTopic(context, id: topicId, path: normalized, title: title);
    return;
  }
  if (normalized.startsWith('/user/')) {
    openProfile(context, path: normalized);
    return;
  }
  openAccountPage(context, normalized.isEmpty ? path : normalized, title: title);
}

String accountErrorText(Object error) {
  if (error is NiniException) return error.message;
  return '$error';
}
