import 'package:flutter/material.dart';

import '../account_models.dart';
import '../data/account_api.dart';
import '../nini_scope.dart';
import '../widgets/status_views.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  PrivateAccount? _private;
  ProfileAccount? _profile;
  ParentingAccount? _parenting;
  List<MailNotice> _notices = const [];
  var _loading = true;
  String? _error;
  String? _status;

  final _name = TextEditingController();
  final _family = TextEditingController();
  final _currentPassword = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _code = TextEditingController();
  final _signature = TextEditingController();
  final _childName = TextEditingController();
  final _childBirth = TextEditingController();
  var _childGender = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  @override
  void dispose() {
    for (final controller in [
      _name,
      _family,
      _currentPassword,
      _newPassword,
      _confirmPassword,
      _email,
      _phone,
      _code,
      _signature,
      _childName,
      _childBirth,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  AccountApi get _api => NiniScope.of(context).account;

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait<Object?>([
        _api.privateInfo(),
        _api.profileInfo(),
        _api.parenting(),
        _api.mailNotices(),
      ]);
      if (!mounted) return;
      final profile = results[1] as ProfileAccount;
      setState(() {
        _private = results[0] as PrivateAccount;
        _profile = profile;
        _parenting = results[2] as ParentingAccount;
        _notices = results[3] as List<MailNotice>;
        _signature.text = profile.signature ?? '';
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

  Future<void> _run(Future<void> Function() action, String success) async {
    setState(() => _status = null);
    try {
      await action();
      if (!mounted) return;
      setState(() => _status = success);
      await _load();
    } catch (error) {
      if (!mounted) return;
      setState(() => _status = '$error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('اطلاعات کاربری')),
      body: _loading
          ? const LoadingState()
          : _error != null
          ? ErrorState(onRetry: _load)
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_status != null) ...[
                  Text(_status!),
                  const SizedBox(height: 12),
                ],
                if (_private?.nickname != null) Text('نام مستعار: ${_private!.nickname}'),
                const SizedBox(height: 16),
                Text('نام و نام خانوادگی', style: Theme.of(context).textTheme.titleMedium),
                TextField(controller: _name, decoration: const InputDecoration(labelText: 'نام')),
                TextField(controller: _family, decoration: const InputDecoration(labelText: 'نام خانوادگی')),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton(
                    onPressed: () => _run(
                      () => _api.changeName(name: _name.text.trim(), family: _family.text.trim()),
                      'اطلاعات با موفقیت تغییر یافت',
                    ),
                    child: const Text('ذخیره'),
                  ),
                ),
                Text('کلمه عبور', style: Theme.of(context).textTheme.titleMedium),
                TextField(
                  controller: _currentPassword,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'کلمه عبور فعلی'),
                ),
                TextField(
                  controller: _newPassword,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'کلمه عبور جدید'),
                ),
                TextField(
                  controller: _confirmPassword,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'تکرار کلمه عبور جدید'),
                ),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton(
                    onPressed: () => _run(
                      () => _api.changePassword(
                        currentPassword: _currentPassword.text,
                        newPassword: _newPassword.text,
                        confirmPassword: _confirmPassword.text,
                      ),
                      'کلمه عبور با موفقیت تغییر کرد',
                    ),
                    child: const Text('تغییر کلمه عبور'),
                  ),
                ),
                Text('پست الکترونیک', style: Theme.of(context).textTheme.titleMedium),
                for (final email in _private?.emails ?? const <ContactChannel>[])
                  _ChannelTile(
                    value: email.value,
                    primary: email.primary,
                    confirmed: email.confirmed,
                    onPrimary: () => _run(() => _api.primaryEmail(email.id), 'پست الکترونیکی با موفقیت به ایمیل اصلی تغییر کرد'),
                    onRemove: () => _run(() => _api.removeEmail(email.id), 'پست الکترونیک با موفقیت حذف شد'),
                    onResend: () => _run(() => _api.resendEmail(email.id), 'ایمیل تایید با موفقیت ارسال شد'),
                  ),
                TextField(controller: _email, decoration: const InputDecoration(labelText: 'پست الکترونیک جدید')),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton(
                    onPressed: () => _run(() => _api.addEmail(_email.text.trim()), 'اطلاعات با موفقیت ثبت شد'),
                    child: const Text('افزودن'),
                  ),
                ),
                Text('تلفن همراه', style: Theme.of(context).textTheme.titleMedium),
                for (final phone in _private?.phones ?? const <ContactChannel>[])
                  _ChannelTile(
                    value: phone.value,
                    primary: phone.primary,
                    confirmed: phone.confirmed,
                    onPrimary: () => _run(() => _api.primaryPhone(phone.id), 'شماره همراه با موفقیت به شماره اصلی تغییر کرد'),
                    onRemove: () => _run(() => _api.removePhone(phone.id), 'شماره همراه با موفقیت حذف شد'),
                    onCode: () => _run(() => _api.sendPhoneCode(phone.id), 'کد تایید با موفقیت ارسال شد'),
                    onVerify: (code) => _run(() => _api.verifyPhone(id: phone.id, code: code), 'شماره همراه تایید شد'),
                  ),
                TextField(controller: _phone, decoration: const InputDecoration(labelText: 'شماره جدید')),
                TextField(controller: _code, decoration: const InputDecoration(labelText: 'کد تایید')),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton(
                    onPressed: () => _run(() => _api.addPhone(_phone.text.trim()), 'اطلاعات با موفقیت ثبت شد'),
                    child: const Text('افزودن شماره تماس'),
                  ),
                ),
                Text('نمایه', style: Theme.of(context).textTheme.titleMedium),
                if (_profile?.gender != null) Text('جنسیت: ${_profile!.gender}'),
                if (_profile?.birthDate != null) Text('تاریخ تولد: ${_profile!.birthDate}'),
                if (_profile?.allowSignature == false)
                  const Text('امکان تغییر امضاء وجود ندارد')
                else ...[
                  TextField(controller: _signature, decoration: const InputDecoration(labelText: 'امضا'), maxLines: 3),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton(
                      onPressed: () {
                        final fields = Map<String, Object?>.from(_profile?.fields ?? const {});
                        fields['SignatureMessage'] = _signature.text;
                        _run(() => _api.editProfile(fields), 'مشخصات با موفقیت تغییر کرد');
                      },
                      child: const Text('ذخیره تغییرات'),
                    ),
                  ),
                ],
                Text('فرزندان و بارداری', style: Theme.of(context).textTheme.titleMedium),
                if (_parenting?.parentingType != null) Text('وضعیت: ${_parenting!.parentingType}'),
                for (final child in _parenting?.children ?? const <ChildInfo>[])
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(child.name),
                    subtitle: Text(child.birthDate ?? ''),
                    trailing: child.id == null
                        ? null
                        : TextButton(
                            onPressed: () => _run(() => _api.removeChild(child.id!), 'آیتم مورد نظر با موفقیت حذف شد'),
                            child: const Text('حذف'),
                          ),
                  ),
                TextField(controller: _childName, decoration: const InputDecoration(labelText: 'نام فرزند')),
                TextField(controller: _childBirth, decoration: const InputDecoration(labelText: 'تاریخ تولد')),
                DropdownButtonFormField<int>(
                  initialValue: _childGender,
                  decoration: const InputDecoration(labelText: 'جنسیت'),
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('مرد')),
                    DropdownMenuItem(value: 2, child: Text('زن')),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _childGender = value);
                  },
                ),
                Wrap(
                  children: [
                    TextButton(
                      onPressed: () => _run(
                        () => _api.addChild(name: _childName.text.trim(), genderType: _childGender, birthDate: _childBirth.text.trim()),
                        'اطلاعات با موفقیت ثبت شد',
                      ),
                      child: const Text('درج وضعیت جدید'),
                    ),
                    TextButton(
                      onPressed: () => _run(_api.addConceive, 'اطلاعات با موفقیت ثبت شد'),
                      child: const Text('در اقدامم'),
                    ),
                    TextButton(
                      onPressed: () => _run(_api.removeConceive, 'آیتم مورد نظر با موفقیت حذف شد'),
                      child: const Text('حذف اقدام'),
                    ),
                    TextButton(
                      onPressed: () => _run(_api.removePregnancyTicker, 'آیتم مورد نظر با موفقیت حذف شد'),
                      child: const Text('حذف نوار بارداری'),
                    ),
                  ],
                ),
                if (_embryoText().isNotEmpty) Text(_embryoText()),
                const SizedBox(height: 12),
                Text('تنظیمات ارسال اعلان به ایمیل', style: Theme.of(context).textTheme.titleMedium),
                for (var index = 0; index < _notices.length; index++)
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _notices[index].checked,
                    title: Text(_notices[index].title),
                    onChanged: (value) {
                      setState(() => _notices[index] = _notices[index].copyWith(checked: value ?? false));
                    },
                  ),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton(
                    onPressed: () => _run(() => _api.saveMailNotices(_notices), 'اطلاعات با موفقیت تغییر یافت'),
                    child: const Text('ذخیره تغییرات'),
                  ),
                ),
              ],
            ),
    );
  }

  String _embryoText() {
    final embryo = _parenting?.embryo ?? const {};
    if (embryo.isEmpty) return '';
    final parts = <String>[];
    for (final entry in embryo.entries) {
      if (entry.value == null || '$entry.value'.isEmpty) continue;
      parts.add('${entry.key}: ${entry.value}');
    }
    return parts.join('\n');
  }
}

class _ChannelTile extends StatelessWidget {
  const _ChannelTile({
    required this.value,
    required this.primary,
    required this.confirmed,
    required this.onPrimary,
    required this.onRemove,
    this.onResend,
    this.onCode,
    this.onVerify,
  });

  final String value;
  final bool primary;
  final bool confirmed;
  final VoidCallback onPrimary;
  final VoidCallback onRemove;
  final VoidCallback? onResend;
  final VoidCallback? onCode;
  final void Function(String code)? onVerify;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$value${primary ? ' · اصلی' : ''}${confirmed ? '' : ' · تایید نشده است'}'),
        Wrap(
          children: [
            if (!primary) TextButton(onPressed: onPrimary, child: const Text('اصلی')),
            TextButton(onPressed: onRemove, child: const Text('حذف')),
            if (onResend != null) TextButton(onPressed: onResend, child: const Text('ارسال ایمیل تایید')),
            if (onCode != null) TextButton(onPressed: onCode, child: const Text('ارسال کد تایید')),
            if (onVerify != null)
              TextButton(
                onPressed: () async {
                  final code = await _askCode(context);
                  if (code != null && code.isNotEmpty) onVerify!(code);
                },
                child: const Text('تایید شماره موبایل'),
              ),
          ],
        ),
      ],
    );
  }

  Future<String?> _askCode(BuildContext context) async {
    final controller = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('کد تایید'),
        content: TextField(controller: controller, decoration: const InputDecoration(labelText: 'کد تایید')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('انصراف')),
          TextButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('تایید')),
        ],
      ),
    );
    controller.dispose();
    return code;
  }
}
