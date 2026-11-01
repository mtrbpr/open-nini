import 'package:flutter/widgets.dart';

import 'data/nini_repository.dart';

class NiniScope extends InheritedNotifier<NiniRepository> {
  const NiniScope({required NiniRepository repository, required super.child, super.key})
    : super(notifier: repository);

  static NiniRepository of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<NiniScope>();
    assert(scope != null, 'NiniScope is missing above this widget');
    return scope!.notifier!;
  }
}
