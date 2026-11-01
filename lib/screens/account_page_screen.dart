import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../account_models.dart';
import '../data/forms.dart';
import '../nini_scope.dart';
import '../widgets/status_views.dart';

class AccountPageScreen extends StatefulWidget {
  const AccountPageScreen({required this.path, this.title, super.key});

  final String path;
  final String? title;

  @override
  State<AccountPageScreen> createState() => _AccountPageScreenState();
}

class _AccountPageScreenState extends State<AccountPageScreen> {
  final _text = <String, TextEditingController>{};
  final _files = <String, ({String filename, Uint8List bytes})>{};
  final _checks = <String, bool>{};
  final _selects = <String, String>{};
  final _recipients = <AccountChoice>[];
  final _search = TextEditingController();
  WebForm? _form;
  String? _searchUrl;
  String? _pageText;
  var _loading = true;
  var _busy = false;
  String? _error;
  List<AccountChoice> _results = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  @override
  void dispose() {
    for (final controller in _text.values) {
      controller.dispose();
    }
    _search.dispose();
    super.dispose();
  }

  bool get _isMessage => widget.path.contains('/profile/conversation/create') || widget.path.contains('/profile/conversation/send');

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = NiniScope.of(context).account;
      WebForm? form;
      String? searchUrl;
      String? text;
      if (_isMessage) {
        final draft = await api.messageDraft();
        form = draft.form;
        searchUrl = draft.searchUrl;
      } else if (widget.path.contains('/profile/photo/upload')) {
        form = await api.uploadForm(path: widget.path, action: '/profile/photo/upload', title: 'آپلود عکس');
      } else if (widget.path.contains('/profile/video/upload')) {
        form = await api.uploadForm(path: widget.path, action: '/profile/video/upload', title: 'آپلود ویدیو');
      } else if (widget.path.contains('/profile/profilepicture')) {
        form = await api.uploadForm(
          path: widget.path,
          action: '/profile/profilepicture',
          title: 'تصویر نمایه',
        );
      } else {
        final page = await api.pageAction(widget.path, title: widget.title);
        form = page.form;
        text = page.text;
      }
      if (!mounted) return;
      if (form == null) {
        setState(() {
          _pageText = text;
          _loading = false;
          _error = text == null ? 'فرم پیدا نشد.' : null;
        });
        return;
      }
      _bind(form, search: searchUrl != null);
      setState(() {
        _form = form;
        _searchUrl = searchUrl;
        _pageText = text;
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

  void _bind(WebForm form, {required bool search}) {
    for (final controller in _text.values) {
      controller.dispose();
    }
    _text.clear();
    _files.clear();
    _checks.clear();
    _selects.clear();
    for (final field in form.fields) {
      if (field.hidden || field.type == 'file' || field.type == 'select' || field.type == 'checkbox') continue;
      if (search && field.name == 'UserIds') continue;
      _text[field.name] = TextEditingController(text: field.value);
    }
    for (final field in form.fields) {
      if (field.type == 'checkbox') _checks[field.name] = field.value == 'true';
      if (field.type == 'select') _selects[field.name] = field.value;
    }
  }

  Map<String, String> _edits() {
    return {
      for (final entry in _text.entries) entry.key: entry.value.text,
      for (final entry in _selects.entries) entry.key: entry.value,
      for (final entry in _checks.entries) entry.key: entry.value ? 'true' : 'false',
      if (_recipients.isNotEmpty) 'UserIds': _recipients.map((item) => item.id).join(','),
    };
  }

  Future<void> _pick(WebField field) async {
    final video = field.name.toLowerCase().contains('video') || (field.label ?? '').contains('ویدیو');
    final file = await FilePicker.pickFile(type: video ? FileType.video : FileType.image);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() => _files[field.name] = (filename: file.name, bytes: bytes));
  }

  Future<void> _findRecipients() async {
    final url = _searchUrl;
    final term = _search.text.trim();
    if (url == null || term.isEmpty) return;
    try {
      final results = await NiniScope.of(context).account.searchRecipients(url, term);
      if (mounted) setState(() => _results = results);
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    }
  }

  Future<void> _submit() async {
    final form = _form;
    if (form == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final api = NiniScope.of(context).account;
      final edits = _edits();
      final fields = form.valuesWith(edits);
      final String? failure;
      final files = form.fields.where((field) => field.type == 'file').toList();
      if (files.isNotEmpty) {
        failure = await api.submitUpload(
          form: form,
          fields: {
            for (final entry in fields.entries)
              if (!files.any((field) => field.name == entry.key)) entry.key: entry.value,
          },
          files: [
            for (final field in files)
              if (_files[field.name] != null)
                (name: field.name, filename: _files[field.name]!.filename, bytes: _files[field.name]!.bytes),
          ],
        );
      } else {
        failure = await api.submitForm(form, edits);
      }
      if (!mounted) return;
      if (failure != null) {
        setState(() => _error = failure);
        return;
      }
      context.pop(true);
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final form = _form;
    return Scaffold(
      appBar: AppBar(title: Text(widget.title ?? form?.title ?? 'فرم')),
      body: _loading
          ? const LoadingState()
          : form == null
          ? (_pageText == null
                ? ErrorState(onRetry: _load)
                : Padding(padding: const EdgeInsets.all(16), child: Text(_pageText!)))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_pageText != null && _pageText!.isNotEmpty) ...[
                  Text(_pageText!),
                  const SizedBox(height: 16),
                ],
                if (_searchUrl != null) ...[
                  TextField(
                    controller: _search,
                    decoration: const InputDecoration(labelText: 'دریافت کننده'),
                    onSubmitted: (_) => _findRecipients(),
                  ),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton(onPressed: _findRecipients, child: const Text('جستجو')),
                  ),
                  for (final choice in _results)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(choice.label),
                      onTap: () => setState(() {
                        if (_recipients.every((item) => item.id != choice.id)) _recipients.add(choice);
                        _results = const [];
                      }),
                    ),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final choice in _recipients)
                        InputChip(
                          label: Text(choice.label),
                          onDeleted: () => setState(() => _recipients.remove(choice)),
                        ),
                    ],
                  ),
                ],
                for (final field in form.fields)
                  if (!field.hidden && !(field.name == 'UserIds' && _searchUrl != null)) ...[
                    if (field.type == 'file')
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(field.label ?? field.name),
                        subtitle: Text(_files[field.name]?.filename ?? 'فایلی انتخاب نشده'),
                        trailing: TextButton(onPressed: () => _pick(field), child: const Text('انتخاب')),
                      )
                    else if (field.type == 'checkbox')
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _checks[field.name] ?? false,
                        title: Text(field.label ?? field.name),
                        onChanged: (value) => setState(() => _checks[field.name] = value ?? false),
                      )
                    else if (field.type == 'select')
                      DropdownButtonFormField<String>(
                        initialValue: field.options.any((option) => option.value == _selects[field.name])
                            ? _selects[field.name]
                            : null,
                        decoration: InputDecoration(labelText: field.label ?? field.name),
                        items: [
                          for (final option in field.options)
                            DropdownMenuItem(value: option.value, child: Text(option.label)),
                        ],
                        onChanged: (value) {
                          if (value != null) setState(() => _selects[field.name] = value);
                        },
                      )
                    else
                      TextField(
                        controller: _text[field.name],
                        obscureText: field.type == 'password',
                        maxLines: field.type == 'textarea' ? 5 : 1,
                        decoration: InputDecoration(labelText: field.label ?? field.name),
                      ),
                    const SizedBox(height: 12),
                  ],
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  ),
                FilledButton(
                  onPressed: _busy ? null : _submit,
                  child: Text(_busy ? '...' : 'ثبت'),
                ),
              ],
            ),
    );
  }
}
