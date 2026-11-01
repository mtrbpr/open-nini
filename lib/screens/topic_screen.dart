import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/compose.dart';
import '../data/dates.dart';
import '../data/nini_client.dart';
import '../models.dart';
import '../nini_scope.dart';
import '../router.dart';
import '../widgets/author_avatar.dart';
import '../widgets/paged_list.dart';
import '../widgets/post_body.dart';
import '../widgets/web_form_screen.dart';

class TopicScreen extends StatefulWidget {
  const TopicScreen({required this.id, required this.title, required this.path, super.key});

  final int id;
  final String title;
  final String path;

  @override
  State<TopicScreen> createState() => _TopicScreenState();
}

class _TopicScreenState extends State<TopicScreen> {
  final _message = TextEditingController();
  String? _title;
  bool? _closed;
  var _listKey = 0;
  var _busy = false;
  String? _error;

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  void _quote(Post post) {
    final quoteId = post.quoteId;
    if (quoteId == null || _closed == true) return;
    _message.text = replyQuote(quoteId, plainFromHtml(post.html));
    _message.selection = TextSelection.collapsed(offset: _message.text.length);
    setState(() => _error = null);
  }

  Future<void> _send() async {
    final text = _message.text.trim();
    if (text.isEmpty) return;
    final repository = NiniScope.of(context);
    if (!repository.signedIn) {
      context.push('/sign-in');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final outcome = await submitWithProfile(
        context,
        () => repository.createReply(topicPath: widget.path, topicId: widget.id, message: text),
      );
      if (!mounted) return;
      if (outcome.topicPath != null) {
        _message.clear();
        setState(() => _listKey++);
        return;
      }
      setState(() => _error = outcome.message ?? 'ارسال انجام نشد.');
    } on NiniException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = (_title == null || _title!.isEmpty) ? widget.title : _title!;
    final closed = _closed == true;
    return Scaffold(
      appBar: AppBar(
        title: Text(title.isEmpty ? 'تاپیک' : title, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: Column(
        children: [
          Expanded(
            child: PagedList<Post>(
              key: ValueKey(_listKey),
              emptyMessage: 'پستی در این تاپیک نیست.',
              idOf: (post) => post.id,
              load: (page) async {
                final result = await NiniScope.of(context).fetchTopic(widget.path, page: page);
                return PageSlice(
                  items: result.posts,
                  lastPage: result.lastPage,
                  title: result.title,
                  locked: result.closed,
                );
              },
              onLoaded: (slice) {
                if (!mounted) return;
                setState(() {
                  final loaded = slice.title;
                  if (loaded != null && loaded.isNotEmpty) _title = loaded;
                  _closed = slice.locked;
                });
              },
              itemBuilder: (context, post) => _PostCard(
                post: post,
                onQuote: closed ? null : () => _quote(post),
              ),
            ),
          ),
          if (closed)
            const Material(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Text(topicLockedMessage, textAlign: TextAlign.center),
              ),
            )
          else if (_closed == false)
            Material(
              elevation: 2,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            _error!,
                            style: TextStyle(color: Theme.of(context).colorScheme.error),
                          ),
                        ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _message,
                              minLines: 1,
                              maxLines: 5,
                              maxLength: 5000,
                              decoration: const InputDecoration(
                                hintText: 'نظر خود را وارد نمایید ...',
                                counterText: '',
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'ارسال نظر',
                            onPressed: _busy ? null : _send,
                            icon: const Icon(Icons.send),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({required this.post, this.onQuote});

  final Post post;
  final VoidCallback? onQuote;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final when = displayPostDate(post.publishedAt, post.dateLabel, post.timeLabel);
    final authorPath = post.authorPath;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AuthorAvatar(url: post.avatarUrl),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: authorPath == null ? null : () => openProfile(context, path: authorPath),
                    child: Text(post.author, style: theme.textTheme.titleSmall),
                  ),
                ),
                if (when.isNotEmpty)
                  Text(
                    when,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (post.quotedHtml != null) QuoteBlock(html: post.quotedHtml!),
            PostBody(html: post.html),
            if (onQuote != null && post.quoteId != null)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton(onPressed: onQuote, child: const Text('پاسخ به پست')),
              ),
          ],
        ),
      ),
    );
  }
}
