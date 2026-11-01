import 'package:flutter/material.dart';

import '../account_models.dart';
import '../nini_scope.dart';
import '../router.dart';
import '../widgets/author_avatar.dart';
import '../widgets/status_views.dart';

class PeopleScreen extends StatefulWidget {
  const PeopleScreen({super.key});

  @override
  State<PeopleScreen> createState() => _PeopleScreenState();
}

class _PeopleScreenState extends State<PeopleScreen> {
  final _query = TextEditingController();
  List<PersonHit> _people = const [];
  var _searched = false;
  var _busy = false;
  String? _error;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final term = _query.text.trim();
    if (term.isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final people = await NiniScope.of(context).account.findPeople(term);
      if (!mounted) return;
      setState(() {
        _people = people;
        _searched = true;
        _busy = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = '$error';
        _busy = false;
        _searched = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('گفتگوی جدید')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _query,
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(labelText: 'نام کاربری', border: OutlineInputBorder()),
              onSubmitted: (_) => _search(),
            ),
          ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: TextButton(onPressed: _busy ? null : _search, child: const Text('جستجو')),
            ),
          ),
          if (_busy)
            const Expanded(child: LoadingState())
          else if (_error != null)
            Expanded(child: ErrorState(onRetry: _search))
          else if (_searched && _people.isEmpty)
            const Expanded(child: EmptyState(message: 'کسی پیدا نشد.'))
          else
            Expanded(
              child: ListView(
                children: [
                  for (final person in _people)
                    ListTile(
                      leading: AuthorAvatar(url: person.avatarUrl),
                      title: Text(person.name),
                      onTap: () => openProfile(context, path: person.path),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
