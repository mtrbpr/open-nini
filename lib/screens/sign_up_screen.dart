import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/nini_client.dart';
import '../nini_scope.dart';
import '../widgets/status_views.dart';
import '../widgets/web_form_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _captcha = TextEditingController();
  Uint8List? _image;
  String? _token;
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
    _phone.dispose();
    _password.dispose();
    _confirm.dispose();
    _captcha.dispose();
    super.dispose();
  }

  Future<void> _load({bool keepError = false}) async {
    setState(() => _loading = true);
    try {
      final challenge = await NiniScope.of(context).signUpChallenge();
      if (!mounted) return;
      setState(() {
        _token = challenge.token;
        _image = challenge.image;
        _loading = false;
        if (!keepError) _error = null;
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
    final token = _token;
    if (token == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final outcome = await NiniScope.of(context).signUp(
        phone: _phone.text,
        password: _password.text,
        confirmPassword: _confirm.text,
        captcha: _captcha.text,
        token: token,
      );
      if (!mounted) return;
      if (outcome.signedIn) {
        context.pop();
        context.pop();
        return;
      }
      final next = outcome.nextForm;
      if (next != null) {
        final saved = await Navigator.of(context).push<bool>(
          MaterialPageRoute(builder: (_) => WebFormScreen(form: next)),
        );
        if (saved == true && mounted) {
          context.pop();
          context.pop();
        }
        return;
      }
      setState(() => _error = outcome.message ?? 'ثبت نام انجام نشد.');
      await _load(keepError: true);
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
    final image = _image;
    return Scaffold(
      appBar: AppBar(title: const Text('ثبت نام')),
      body: _loading
          ? const LoadingState()
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('با ثبت نام، قوانین و مقررات نی‌نی‌سایت را می‌پذیرید.'),
                const SizedBox(height: 12),
                TextField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'شماره موبایل'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _password,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'کلمه عبور'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _confirm,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'تکرار کلمه عبور'),
                ),
                const SizedBox(height: 12),
                if (image != null)
                  Row(
                    children: [
                      Image.memory(image, height: 64, fit: BoxFit.contain),
                      IconButton(
                        onPressed: _busy ? null : _load,
                        icon: const Icon(Icons.refresh),
                        tooltip: 'تصویر تازه',
                      ),
                    ],
                  ),
                TextField(
                  controller: _captcha,
                  decoration: const InputDecoration(labelText: 'عبارت امنیتی'),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ],
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _busy || _token == null ? null : _submit,
                  child: Text(_busy ? '...' : 'ثبت نام'),
                ),
              ],
            ),
    );
  }
}
