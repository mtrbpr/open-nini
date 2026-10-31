import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'models.dart';
import 'screens/board_screen.dart';
import 'screens/discussion_screen.dart';
import 'screens/home_screen.dart';
import 'screens/topic_screen.dart';

GoRouter createRouter() {
  return GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/category/:id',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          final name = state.uri.queryParameters['name'] ?? '';
          return DiscussionScreen(id: id, name: name);
        },
      ),
      GoRoute(
        path: '/forum/:id',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          final name = state.uri.queryParameters['name'] ?? '';
          final path = state.uri.queryParameters['path'] ?? '/discussion/forum/$id';
          return BoardScreen(id: id, name: name, path: path);
        },
      ),
      GoRoute(
        path: '/topic/:id',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          final title = state.uri.queryParameters['title'] ?? '';
          final path = state.uri.queryParameters['path'] ?? '/discussion/topic/$id';
          return TopicScreen(id: id, title: title, path: path);
        },
      ),
    ],
  );
}

void openDiscussion(BuildContext context, BoardGroup group) {
  context.push(
    Uri(
      path: '/category/${group.id}',
      queryParameters: {'name': group.name},
    ).toString(),
  );
}

void openBoard(BuildContext context, Board board) {
  context.push(
    Uri(
      path: '/forum/${board.id}',
      queryParameters: {
        'name': board.name,
        'path': board.path,
      },
    ).toString(),
  );
}

void openTopic(
  BuildContext context, {
  required int id,
  required String path,
  String? title,
}) {
  context.push(
    Uri(
      path: '/topic/$id',
      queryParameters: {
        'path': path,
        if (title != null && title.isNotEmpty) 'title': title,
      },
    ).toString(),
  );
}
