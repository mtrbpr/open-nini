class WebOption {
  const WebOption({required this.value, required this.label});

  final String value;
  final String label;
}

class WebField {
  const WebField({
    required this.name,
    required this.type,
    this.label,
    this.value = '',
    this.placeholder,
    this.options = const [],
  });

  final String name;
  final String type;
  final String? label;
  final String value;
  final String? placeholder;
  final List<WebOption> options;

  bool get hidden => type == 'hidden';
}

class WebForm {
  const WebForm({required this.action, required this.fields, this.title});

  final String action;
  final List<WebField> fields;
  final String? title;

  Map<String, String> valuesWith(Map<String, String> edits) {
    return {
      for (final field in fields) field.name: edits[field.name] ?? field.value,
    };
  }
}

class AuthOutcome {
  const AuthOutcome({this.signedIn = false, this.message, this.nextForm});

  final bool signedIn;
  final String? message;
  final WebForm? nextForm;

  bool get accepted => message == null && nextForm == null;
}

class ComposeOutcome {
  const ComposeOutcome({this.topicPath, this.message, this.profileForm});

  final String? topicPath;
  final String? message;
  final WebForm? profileForm;
}
