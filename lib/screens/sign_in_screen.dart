import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../nini_scope.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  var _remember = true;
  var _busy = false;
  String? _error;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final outcome = await NiniScope.of(context).signIn(
        username: _username.text,
        password: _password.text,
        remember: _remember,
      );
      if (!mounted) return;
      if (outcome.signedIn) {
        context.pop();
        return;
      }
      setState(() => _error = outcome.message ?? 'ورود انجام نشد.');
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ورود')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _username,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'شماره موبایل یا ایمیل'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _password,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'کلمه عبور'),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _remember,
            onChanged: (value) => setState(() => _remember = value ?? false),
            title: const Text('مرا به خاطر بسپار'),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          FilledButton(
            onPressed: _busy ? null : _submit,
            child: Text(_busy ? '...' : 'ورود'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => context.push('/sign-up'),
            child: const Text('در نی‌نی‌سایت عضو شوید'),
          ),
        ],
      ),
    );
  }
}
