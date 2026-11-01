import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'models.dart';
import 'screens/account_hub_screen.dart';
import 'screens/account_page_screen.dart';
import 'screens/account_section_screen.dart';
import 'screens/app_shell.dart';
import 'screens/board_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/discussion_screen.dart';
import 'screens/home_screen.dart';
import 'screens/inbox_screen.dart';
import 'screens/new_topic_screen.dart';
import 'screens/people_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/sign_in_screen.dart';
import 'screens/sign_up_screen.dart';
import 'screens/topic_screen.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createRouter() {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/messages',
                builder: (context, state) => const InboxScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/me',
                builder: (context, state) => const AccountHubScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/category/:id',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          final name = state.uri.queryParameters['name'] ?? '';
          return DiscussionScreen(id: id, name: name);
        },
      ),
      GoRoute(
        path: '/forum/:id',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          final name = state.uri.queryParameters['name'] ?? '';
          final path = state.uri.queryParameters['path'] ?? '/discussion/forum/$id';
          return BoardScreen(id: id, name: name, path: path);
        },
      ),
      GoRoute(
        path: '/sign-in',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: '/sign-up',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: '/profile',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final path = state.uri.queryParameters['path'];
          if (path == null || path.isEmpty) return const AccountHubScreen();
          return ProfileScreen(path: path);
        },
      ),
      GoRoute(
        path: '/account/page',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => AccountPageScreen(
          path: state.uri.queryParameters['path'] ?? '/profile',
          title: state.uri.queryParameters['title'],
        ),
      ),
      GoRoute(
        path: '/account/:section',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => AccountSectionScreen(section: state.pathParameters['section']!),
      ),
      GoRoute(
        path: '/people',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const PeopleScreen(),
      ),
      GoRoute(
        path: '/chat',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => ChatScreen(
          name: state.uri.queryParameters['name'] ?? '',
          avatarUrl: state.uri.queryParameters['avatar'],
          userPath: state.uri.queryParameters['user'],
        ),
      ),
      GoRoute(
        path: '/new-topic',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => NewTopicScreen(
          boardPath: state.uri.queryParameters['path'] ?? '',
          boardName: state.uri.queryParameters['name'] ?? '',
        ),
      ),
      GoRoute(
        path: '/topic/:id',
        parentNavigatorKey: rootNavigatorKey,
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

void openAccountPage(BuildContext context, String path, {String? title}) {
  context.push(
    Uri(
      path: '/account/page',
      queryParameters: {
        'path': path,
        if (title != null && title.isNotEmpty) 'title': title,
      },
    ).toString(),
  );
}

void openProfile(BuildContext context, {String? path}) {
  context.push(
    Uri(
      path: '/profile',
      queryParameters: {if (path != null && path.isNotEmpty) 'path': path},
    ).toString(),
  );
}

void openNewTopic(BuildContext context, {required String path, String? name}) {
  context.push(
    Uri(
      path: '/new-topic',
      queryParameters: {
        'path': path,
        if (name != null && name.isNotEmpty) 'name': name,
      },
    ).toString(),
  );
}

Future<Object?> openChat(
  BuildContext context, {
  required String name,
  String? avatarUrl,
  String? userPath,
}) {
  return context.push(
    Uri(
      path: '/chat',
      queryParameters: {
        'name': name,
        if (avatarUrl != null && avatarUrl.isNotEmpty) 'avatar': avatarUrl,
        if (userPath != null && userPath.isNotEmpty) 'user': userPath,
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
