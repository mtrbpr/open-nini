import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/status_views.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.go('/messages');
    });
  }

  @override
  Widget build(BuildContext context) => const LoadingState();
}
