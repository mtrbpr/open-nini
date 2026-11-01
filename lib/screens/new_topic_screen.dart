import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/nini_client.dart';
import '../models.dart';
import '../nini_scope.dart';
import '../widgets/status_views.dart';
import '../widgets/web_form_screen.dart';

class NewTopicScreen extends StatefulWidget {
  const NewTopicScreen({required this.boardPath, required this.boardName, super.key});

  final String boardPath;
  final String boardName;

  @override
  State<NewTopicScreen> createState() => _NewTopicScreenState();
}

class _NewTopicScreenState extends State<NewTopicScreen> {
  final _subject = TextEditingController();
  final _message = TextEditingController();
  List<ForumCategory> _categories = const [];
  int? _categoryId;
  int? _forumId;
  var _loading = true;
  var _busy = false;
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
    _subject.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repository = NiniScope.of(context);
      final board = await repository.fetchBoard(widget.boardPath);
      final categories = await repository.fetchCategories();
      if (!mounted) return;
      final categoryId = _matchingCategory(categories, board.categoryId, board.forumId);
      final forumId = _matchingForum(categories, categoryId, board.forumId);
      setState(() {
        _categories = categories;
        _categoryId = categoryId;
        _forumId = forumId;
        _loading = false;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = '$error';
        });
      }
    }
  }

  Future<void> _submit() async {
    final categoryId = _categoryId;
    final forumId = _forumId;
    if (categoryId == null || forumId == null) {
      setState(() => _error = 'دسته و تالار را انتخاب کنید.');
      return;
    }
    if (_subject.text.trim().isEmpty || _message.text.trim().isEmpty) {
      setState(() => _error = 'عنوان و متن لازم است.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final outcome = await submitWithProfile(
        context,
        () => NiniScope.of(context).createTopic(
          boardPath: widget.boardPath,
          subject: _subject.text,
          message: _message.text,
          categoryId: categoryId,
          forumId: forumId,
        ),
      );
      if (!mounted) return;
      final path = outcome.topicPath;
      if (path != null) {
        final id = RegExp(r'/discussion/topic/(\d+)').firstMatch(path);
        final topicId = int.tryParse(id?.group(1) ?? '');
        if (topicId == null) {
          setState(() => _error = 'تاپیک ساخته شد، اما باز نشد.');
          return;
        }
        context.pushReplacement(
          Uri(
            path: '/topic/$topicId',
            queryParameters: {'path': path, 'title': _subject.text.trim()},
          ).toString(),
        );
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
    final signedIn = NiniScope.of(context).signedIn;
    final forums = _categories.where((category) => category.id == _categoryId).expand((category) => category.forums);
    return Scaffold(
      appBar: AppBar(title: const Text('تاپیک جدید')),
      body: _loading
          ? const LoadingState()
          : !signedIn
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('برای ایجاد تاپیک وارد شوید.'),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => context.push('/sign-in'),
                    child: const Text('ورود'),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (widget.boardName.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(widget.boardName),
                  ),
                TextField(
                  controller: _subject,
                  maxLength: 100,
                  decoration: const InputDecoration(labelText: 'عنوان'),
                ),
                TextField(
                  controller: _message,
                  maxLength: 5000,
                  minLines: 5,
                  maxLines: 10,
                  decoration: const InputDecoration(labelText: 'متن'),
                ),
                const SizedBox(height: 12),
                if (_categories.isEmpty)
                  const Text('دسته‌ای برای این تالار پیدا نشد.')
                else ...[
                  DropdownButtonFormField<int>(
                    key: ValueKey('category-$_categoryId'),
                    initialValue: _categoryId,
                    decoration: const InputDecoration(labelText: 'دسته بندی'),
                    items: [
                      for (final category in _categories)
                        DropdownMenuItem(value: category.id, child: Text(category.name)),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _categoryId = value;
                        _forumId = _matchingForum(_categories, value, null);
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    key: ValueKey('forum-$_categoryId-$_forumId'),
                    initialValue: forums.any((forum) => forum.id == _forumId) ? _forumId : null,
                    decoration: const InputDecoration(labelText: 'تالار'),
                    items: [
                      for (final forum in forums) DropdownMenuItem(value: forum.id, child: Text(forum.name)),
                    ],
                    onChanged: (value) => setState(() => _forumId = value),
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ],
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _busy ? null : _submit,
                  child: Text(_busy ? '...' : 'ارسال'),
                ),
              ],
            ),
    );
  }
}

int? _matchingCategory(List<ForumCategory> categories, int? categoryId, int? forumId) {
  for (final category in categories) {
    if (category.id == categoryId) return category.id;
  }
  for (final category in categories) {
    if (category.forums.any((forum) => forum.id == forumId)) return category.id;
  }
  return categories.isEmpty ? null : categories.first.id;
}

int? _matchingForum(List<ForumCategory> categories, int? categoryId, int? forumId) {
  final category = categories.where((item) => item.id == categoryId);
  if (category.isEmpty) return null;
  final forums = category.first.forums;
  for (final forum in forums) {
    if (forum.id == forumId) return forum.id;
  }
  return forums.isEmpty ? null : forums.first.id;
}
