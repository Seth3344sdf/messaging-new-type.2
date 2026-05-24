import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/command_palette.dart';
import 'screens/home_shell.dart';
import 'state/app_state.dart';
import 'theme/theme.dart';

class MessagingApp extends StatelessWidget {
  const MessagingApp({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return MaterialApp(
      title: 'Messaging',
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: app.darkMode ? ThemeMode.dark : ThemeMode.light,
      home: const HomeShell(),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: MediaQuery.of(context).textScaler.clamp(
                  minScaleFactor: 0.9,
                  maxScaleFactor: 1.4,
                ),
          ),
          child: GlobalShortcuts(child: child!),
        );
      },
    );
  }
}
