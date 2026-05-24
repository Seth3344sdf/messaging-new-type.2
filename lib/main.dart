import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import 'app.dart';
import 'config/env.dart';
import 'services/backend.dart';
import 'services/supabase_backend.dart';
import 'state/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Sentry — off unless a DSN is configured.
  if (Env.hasSentry) {
    await SentryFlutter.init(
      (options) {
        options.dsn = Env.sentryDsn;
        options.release = Env.appVersion;
        options.tracesSampleRate = 0.2;
      },
    );
  }

  Backend? backend;
  if (Env.hasBackend) {
    await Supabase.initialize(
      url: Env.supabaseUrl,
      anonKey: Env.supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(autoRefreshToken: true),
      realtimeClientOptions: const RealtimeClientOptions(
        logLevel: RealtimeLogLevel.info,
      ),
    );
    backend = SupabaseBackend(Supabase.instance.client);
    // ignore: avoid_print
    print('[backend] Supabase initialized at ${Env.supabaseUrl}');
  } else {
    // ignore: avoid_print
    print('[backend] No SUPABASE_URL configured — mock-data mode. '
        'See BACKEND.md to wire up a real backend.');
  }

  final appState = AppState(backend: backend);
  // Rebootstrap whenever auth changes so the cache matches the signed-in user.
  if (backend != null) {
    backend.authChanges.listen((user) async {
      if (user != null) {
        await appState.bootstrap();
      }
    });
    // If already signed in at start, bootstrap now.
    if (backend.currentUser != null) {
      await appState.bootstrap();
    }
  } else {
    await appState.bootstrap();
  }

  final app = MultiProvider(
    providers: [
      Provider<Backend?>.value(value: backend),
      ChangeNotifierProvider<AppState>.value(value: appState),
    ],
    child: const MessagingApp(),
  );

  if (Env.hasSentry) {
    runApp(SentryWidget(child: app));
  } else {
    runApp(app);
  }
}
