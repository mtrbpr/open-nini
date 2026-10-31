import 'package:flutter/widgets.dart';

import 'data/nini_repository.dart';

class NiniScope extends InheritedWidget {
  const NiniScope({required this.repository, required super.child, super.key});

  final NiniRepository repository;

  static NiniRepository of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<NiniScope>();
    assert(scope != null, 'NiniScope is missing above this widget');
    return scope!.repository;
  }

  @override
  bool updateShouldNotify(NiniScope oldWidget) => repository != oldWidget.repository;
}
