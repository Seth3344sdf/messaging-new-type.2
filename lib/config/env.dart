/// App configuration. Values come from `--dart-define` at build time so
/// secrets never live in source.
///
/// Example:
///   flutter run --dart-define=SUPABASE_URL=https://xxx.supabase.co \
///               --dart-define=SUPABASE_ANON_KEY=eyJhb...
///
/// If both vars are present the app uses the real Supabase backend.
/// Otherwise it runs in mock-data mode and the UI shows seeded demo data.
class Env {
  Env._();

  static const supabaseUrl =
      String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  static const supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

  static const sentryDsn =
      String.fromEnvironment('SENTRY_DSN', defaultValue: '');
  static const appVersion =
      String.fromEnvironment('APP_VERSION', defaultValue: 'dev');

  static bool get hasBackend =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  static bool get hasSentry => sentryDsn.isNotEmpty;
}
