import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class InboxSignal extends InheritedWidget {
  const InboxSignal({required this.tick, required super.child, super.key});

  final int tick;

  static int of(BuildContext context) {
    final signal = context.dependOnInheritedWidgetOfExactType<InboxSignal>();
    return signal?.tick ?? 0;
  }

  @override
  bool updateShouldNotify(InboxSignal oldWidget) => tick != oldWidget.tick;
}

class AppShell extends StatefulWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  var _lastIndex = -1;
  var _inboxTick = 0;

  @override
  Widget build(BuildContext context) {
    final index = widget.navigationShell.currentIndex;
    if (index == 1 && _lastIndex != 1) {
      _lastIndex = 1;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _inboxTick++);
      });
    } else if (index != _lastIndex) {
      _lastIndex = index;
    }
    return InboxSignal(
      tick: _inboxTick,
      child: Scaffold(
        body: widget.navigationShell,
        bottomNavigationBar: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: (selected) {
            widget.navigationShell.goBranch(selected, initialLocation: selected == index);
          },
          destinations: const [
            NavigationDestination(icon: Icon(Icons.forum_outlined), selectedIcon: Icon(Icons.forum), label: 'تبادل نظر'),
            NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline),
              selectedIcon: Icon(Icons.chat_bubble),
              label: 'پیام‌ها',
            ),
          ],
        ),
      ),
    );
  }
}
