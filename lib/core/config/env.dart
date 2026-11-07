/// Configurazione letta a compile time da `--dart-define-from-file=.env`.
abstract final class Env {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static bool get isConfigured =>
      supabaseUrl.startsWith('https://') &&
      !supabaseUrl.contains('YOUR_PROJECT_REF') &&
      supabaseAnonKey.isNotEmpty &&
      supabaseAnonKey != 'YOUR_ANON_KEY';
}
