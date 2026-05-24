import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'config/env.dart';
import 'services/backend.dart';
import 'services/supabase_backend.dart';
import 'state/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase if env vars are present. Otherwise the app runs in
  // mock-data mode — see lib/data/mock_data.dart and BACKEND.md.
  Backend? backend;
  if (Env.hasBackend) {
    await Supabase.initialize(
      url: Env.supabaseUrl,
      anonKey: Env.supabaseAnonKey,
      // Persist sessions across launches.
      authOptions: const FlutterAuthClientOptions(
        autoRefreshToken: true,
      ),
      realtimeClientOptions: const RealtimeClientOptions(
        logLevel: RealtimeLogLevel.info,
      ),
    );
    backend = SupabaseBackend(Supabase.instance.client);
    // ignore: avoid_print
    print('[backend] Supabase initialized at ${Env.supabaseUrl}');
  } else {
    // ignore: avoid_print
    print('[backend] No SUPABASE_URL configured — running in mock-data mode. '
        'See BACKEND.md to wire up a real backend.');
  }

  runApp(
    MultiProvider(
      providers: [
        Provider<Backend?>.value(value: backend),
        ChangeNotifierProvider(create: (_) => AppState()..bootstrap()),
      ],
      child: const MessagingApp(),
    ),
  );
}
