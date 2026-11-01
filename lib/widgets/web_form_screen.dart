import 'package:flutter/material.dart';

import '../data/forms.dart';
import '../nini_scope.dart';

class WebFormScreen extends StatefulWidget {
  const WebFormScreen({required this.form, super.key});

  final WebForm form;

  @override
  State<WebFormScreen> createState() => _WebFormScreenState();
}

class _WebFormScreenState extends State<WebFormScreen> {
  late final Map<String, TextEditingController> _text = {
    for (final field in widget.form.fields)
      if (!field.hidden && field.type != 'select' && field.type != 'checkbox')
        field.name: TextEditingController(text: field.value),
  };
  late final Map<String, String> _selects = {
    for (final field in widget.form.fields)
      if (field.type == 'select') field.name: field.value,
  };
  late final Map<String, bool> _checks = {
    for (final field in widget.form.fields)
      if (field.type == 'checkbox') field.name: field.value == 'true',
  };
  var _busy = false;
  String? _error;

  @override
  void dispose() {
    for (final controller in _text.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Map<String, String> _edits() {
    return {
      for (final entry in _text.entries) entry.key: entry.value.text,
      for (final entry in _selects.entries) entry.key: entry.value,
      for (final entry in _checks.entries) entry.key: entry.value ? 'true' : 'false',
    };
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final outcome = await NiniScope.of(context).submitWebForm(widget.form, _edits());
      if (!mounted) return;
      if (outcome.accepted) {
        Navigator.of(context).pop(true);
        return;
      }
      if (outcome.nextForm != null) {
        final saved = await Navigator.of(context).push<bool>(
          MaterialPageRoute(builder: (_) => WebFormScreen(form: outcome.nextForm!)),
        );
        if (saved == true && mounted) Navigator.of(context).pop(true);
        return;
      }
      setState(() => _error = outcome.message ?? 'ذخیره انجام نشد.');
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final visible = widget.form.fields.where((field) => !field.hidden);
    return Scaffold(
      appBar: AppBar(title: Text(widget.form.title ?? 'فرم')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final field in visible) ...[
            _FieldEditor(
              field: field,
              controller: _text[field.name],
              selected: _selects[field.name],
              checked: _checks[field.name] ?? false,
              onSelected: (value) => setState(() => _selects[field.name] = value),
              onChecked: (value) => setState(() => _checks[field.name] = value),
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

class _FieldEditor extends StatelessWidget {
  const _FieldEditor({
    required this.field,
    required this.checked,
    required this.onSelected,
    required this.onChecked,
    this.controller,
    this.selected,
  });

  final WebField field;
  final TextEditingController? controller;
  final String? selected;
  final bool checked;
  final ValueChanged<String> onSelected;
  final ValueChanged<bool> onChecked;

  @override
  Widget build(BuildContext context) {
    final label = field.label ?? field.name;
    if (field.type == 'checkbox') {
      return CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        value: checked,
        onChanged: (value) => onChecked(value ?? false),
        title: Text(label),
      );
    }
    if (field.type == 'select') {
      return DropdownButtonFormField<String>(
        initialValue: field.options.any((option) => option.value == selected) ? selected : null,
        decoration: InputDecoration(labelText: label),
        items: [
          for (final option in field.options)
            DropdownMenuItem(value: option.value, child: Text(option.label)),
        ],
        onChanged: (value) {
          if (value != null) onSelected(value);
        },
      );
    }
    return TextField(
      controller: controller,
      obscureText: field.type == 'password',
      maxLines: field.type == 'textarea' ? 5 : 1,
      keyboardType: field.type == 'tel' ? TextInputType.phone : TextInputType.text,
      decoration: InputDecoration(labelText: label, hintText: field.placeholder),
    );
  }
}

Future<ComposeOutcome> submitWithProfile(
  BuildContext context,
  Future<ComposeOutcome> Function() send,
) async {
  var challenged = false;
  while (true) {
    final outcome = await send();
    final form = outcome.profileForm;
    if (form == null || challenged || !context.mounted) return outcome;
    challenged = true;
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => WebFormScreen(form: form)),
    );
    if (saved != true) return const ComposeOutcome(message: 'برای ارسال باید نمایه را کامل کنید.');
  }
}
