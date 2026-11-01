import 'package:flutter/material.dart';

import 'activity_screen.dart';
import 'dashboard_screen.dart';
import 'friends_screen.dart';
import 'messages_screen.dart';
import 'notifications_screen.dart';
import 'settings_screen.dart';

class AccountSectionScreen extends StatelessWidget {
  const AccountSectionScreen({required this.section, super.key});

  final String section;

  @override
  Widget build(BuildContext context) {
    return switch (section) {
      'settings' => const SettingsScreen(),
      'messages' => const MessagesScreen(),
      'friends' => const FriendsScreen(),
      'notifications' => const NotificationsScreen(),
      'forum' => const ActivityScreen(kind: 'forum'),
      'clinic' => const ActivityScreen(kind: 'clinic'),
      'photo' => const ActivityScreen(kind: 'photo'),
      'video' => const ActivityScreen(kind: 'video'),
      _ => const DashboardScreen(),
    };
  }
}
