import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'data/nini_repository.dart';
import 'nini_scope.dart';
import 'router.dart';
import 'theme.dart';

class OpenNiniApp extends StatefulWidget {
  const OpenNiniApp({this.repository, super.key});

  final NiniRepository? repository;

  @override
  State<OpenNiniApp> createState() => _OpenNiniAppState();
}

class _OpenNiniAppState extends State<OpenNiniApp> {
  late final NiniRepository _repository = widget.repository ?? NiniRepository();
  late final _router = createRouter();

  @override
  Widget build(BuildContext context) {
    return NiniScope(
      repository: _repository,
      child: MaterialApp.router(
        title: 'nini',
        debugShowCheckedModeBanner: false,
        locale: const Locale('fa', 'IR'),
        supportedLocales: const [Locale('fa', 'IR')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
        themeMode: ThemeMode.system,
        routerConfig: _router,
        builder: (context, child) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: child ?? const SizedBox.shrink(),
          );
        },
      ),
    );
  }
}
