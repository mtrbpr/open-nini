import 'data/forms.dart';

class AccountShell {
  const AccountShell({
    required this.name,
    required this.entries,
    this.avatarUrl,
    this.joined,
    this.publicPath,
  });

  final String name;
  final String? avatarUrl;
  final String? joined;
  final String? publicPath;
  final List<AccountMenuEntry> entries;
}

class AccountMenuEntry {
  const AccountMenuEntry({required this.title, this.path});

  final String title;
  final String? path;

  bool get isHeading => path == null;
}

class CountLine {
  const CountLine({required this.label, required this.value});

  final String label;
  final int value;
}

class AccountRecord {
  const AccountRecord({
    required this.title,
    this.subtitle,
    this.imageUrl,
    this.path,
    this.editPath,
    this.messagePath,
    this.id,
    this.unread = false,
    this.open,
    this.action,
    this.fields = const {},
  });

  final String title;
  final String? subtitle;
  final String? imageUrl;
  final String? path;
  final String? editPath;
  final String? messagePath;
  final int? id;
  final bool unread;
  final bool? open;
  final String? action;
  final Map<String, String> fields;
}

class AccountSlice {
  const AccountSlice({required this.records, required this.total});

  final List<AccountRecord> records;
  final int total;

  bool hasMore(int offset) => offset + records.length < total;
}

class NoticePage {
  const NoticePage({required this.records, this.deleteUrl});

  final List<AccountRecord> records;
  final String? deleteUrl;
}

class MessageDraft {
  const MessageDraft({required this.form, this.searchUrl});

  final WebForm form;
  final String? searchUrl;
}

class AccountChoice {
  const AccountChoice({required this.id, required this.label});

  final String id;
  final String label;
}

class PrivateAccount {
  const PrivateAccount({
    required this.nickname,
    required this.emails,
    required this.phones,
  });

  final String? nickname;
  final List<ContactChannel> emails;
  final List<ContactChannel> phones;
}

class ContactChannel {
  const ContactChannel({
    required this.id,
    required this.value,
    required this.primary,
    required this.confirmed,
  });

  final int id;
  final String value;
  final bool primary;
  final bool confirmed;
}

class ProfileAccount {
  const ProfileAccount({
    required this.fields,
    this.gender,
    this.birthDate,
    this.signature,
    this.allowSignature = false,
  });

  final Map<String, Object?> fields;
  final String? gender;
  final String? birthDate;
  final String? signature;
  final bool allowSignature;
}

class ChildInfo {
  const ChildInfo({this.id, required this.name, this.genderType, this.birthDate});

  final int? id;
  final String name;
  final int? genderType;
  final String? birthDate;
}

class ParentingAccount {
  const ParentingAccount({
    required this.parentingType,
    required this.children,
    required this.embryo,
    required this.conceive,
  });

  final int? parentingType;
  final List<ChildInfo> children;
  final Map<String, Object?> embryo;
  final Map<String, Object?> conceive;
}

class MailNotice {
  const MailNotice({required this.id, required this.title, required this.checked});

  final int id;
  final String title;
  final bool checked;

  MailNotice copyWith({bool? checked}) {
    return MailNotice(id: id, title: title, checked: checked ?? this.checked);
  }

  Map<String, Object?> toJson() => {'Id': id, 'Title': title, 'Checked': checked};
}
