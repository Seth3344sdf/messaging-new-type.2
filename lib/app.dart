import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'models/user.dart';
import 'screens/command_palette.dart';
import 'screens/home_shell.dart';
import 'screens/onboarding_screen.dart';
import 'screens/sign_in_screen.dart';
import 'services/backend.dart';
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
      home: const _Root(),
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

/// Root gate. If a real [Backend] is configured we require auth + onboarding;
/// otherwise we drop straight into the mock-data demo shell.
class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    final backend = context.watch<Backend?>();
    final app = context.watch<AppState>();
    if (backend == null) {
      return const HomeShell();
    }
    return StreamBuilder<AppUser?>(
      stream: backend.authChanges,
      initialData: backend.currentUser,
      builder: (context, snapshot) {
        final user = snapshot.data;
        if (user == null) return const SignInScreen();
        if (!app.ready) return const _Bootstrapping();
        if (app.needsOnboarding) return const OnboardingScreen();
        return const HomeShell();
      },
    );
  }
}

class _Bootstrapping extends StatelessWidget {
  const _Bootstrapping();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}
