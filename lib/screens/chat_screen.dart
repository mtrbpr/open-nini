import 'package:flutter/material.dart';

import '../account_models.dart';
import '../data/parsers/chat_parser.dart';
import '../nini_scope.dart';
import '../widgets/account_widgets.dart';
import '../widgets/status_views.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({required this.name, this.avatarUrl, this.userPath, super.key});

  final String name;
  final String? avatarUrl;
  final String? userPath;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _text = TextEditingController();
  ChatView? _view;
  var _loading = true;
  var _failed = false;
  var _busy = false;
  var _blocked = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  String? get _guid => userGuid(widget.userPath);

  Future<void> _load() async {
    setState(() {
      _loading = _view == null;
      _failed = false;
    });
    try {
      final api = NiniScope.of(context).account;
      final view = await api.conversation(widget.name, avatarUrl: widget.avatarUrl);
      final guid = _guid;
      final friend = guid == null || view.messages.isNotEmpty || await api.isFriend(guid);
      if (!mounted) return;
      setState(() {
        _view = view;
        _blocked = !friend;
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

  Future<void> _send() async {
    final message = _text.text.trim();
    if (message.isEmpty || _busy) return;
    if (message.length > 4000) {
      setState(() => _error = 'متن پیام بلندتر از حد مجاز است.');
      return;
    }
    final view = _view;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final api = NiniScope.of(context).account;
      final String? failure;
      final conversationId = view?.replyConversationId;
      final token = view?.replyToken;
      if (conversationId != null && token != null) {
        failure = await api.replyTo(
          action: view?.replyAction ?? '/profile/conversation/reply',
          conversationId: conversationId,
          message: message,
          token: token,
        );
      } else if (widget.userPath != null) {
        failure = await api.sendFirstMessage(profilePath: widget.userPath!, message: message);
      } else {
        failure = 'این گفتگو هنوز شروع نشده است.';
      }
      if (!mounted) return;
      if (friendsOnlyFailure(failure)) {
        setState(() {
          _blocked = true;
          _error = null;
        });
        return;
      }
      if (failure != null) {
        setState(() => _error = failure);
        return;
      }
      _text.clear();
      await _load();
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _invite() async {
    final path = widget.userPath;
    if (path == null || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final failure = await NiniScope.of(context).account.inviteFriend(path);
      if (!mounted) return;
      if (failure != null) {
        setState(() => _error = failure);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('درخواست دوستی فرستاده شد.')));
      }
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete(ChatMessage message) async {
    final view = _view;
    final id = message.id;
    final conversationId = message.conversationId;
    final action = view?.deleteMessageUrl;
    if (view == null || id == null || conversationId == null || action == null) return;
    final confirmed = await confirmAccountAction(context, 'این پیام حذف شود؟');
    if (!confirmed || !mounted) return;
    setState(() => _busy = true);
    try {
      final failure = await NiniScope.of(context).account.deleteChatMessage(
        action: action,
        conversationId: conversationId,
        messageId: id,
        token: view.replyToken,
      );
      if (!mounted) return;
      if (failure != null) {
        setState(() => _error = failure);
        return;
      }
      await _load();
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.name)),
      body: _loading
          ? const LoadingState()
          : _failed
          ? ErrorState(onRetry: _load)
          : Column(
              children: [
                Expanded(child: _messages()),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                    child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  ),
                _blocked ? _inviteBar() : _composer(),
              ],
            ),
    );
  }

  Widget _messages() {
    final messages = _view?.messages ?? const <ChatMessage>[];
    if (messages.isEmpty) {
      return const EmptyState(message: 'هنوز پیامی در این گفتگو نیست.');
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final scheme = Theme.of(context).colorScheme;
        return Align(
          alignment: message.mine ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
          child: GestureDetector(
            onLongPress: message.mine ? () => _delete(message) : null,
            child: Container(
              constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.78),
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: message.mine ? scheme.primaryContainer : scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(message.body),
            ),
          ),
        );
      },
    );
  }

  Widget _composer() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _text,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(hintText: 'پیام', border: OutlineInputBorder()),
              ),
            ),
            IconButton(
              tooltip: 'ارسال',
              onPressed: _busy ? null : _send,
              icon: _busy
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inviteBar() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Column(
          children: [
            const Text(
              'برای فرستادن پیام، اول باید دوست شوید. بعد از پذیرفتن درخواست می‌توانید پیام بفرستید.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            FilledButton(onPressed: _busy || widget.userPath == null ? null : _invite, child: const Text('دعوت به دوستی')),
          ],
        ),
      ),
    );
  }
}
