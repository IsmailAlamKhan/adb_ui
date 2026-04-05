/// Supabase project URL and anon key (safe to embed in the client).
/// Leave [url] empty to run the app without cloud sign-in or licensing sync.
class SupabaseConfig {
  static const String url = '';
  static const String anonKey = '';

  static bool get isConfigured =>
      url.isNotEmpty && anonKey.isNotEmpty && !url.contains('your-project');
}
