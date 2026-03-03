// Stub for non-web platforms. Server-set anon_id is only used on web (cookie).

/// Returns null on mobile/desktop; anon_id is obtained from SharedPreferences only.
Future<String?> fetchAnonIdFromServer(String supabaseUrl, String anonKey) async {
  return null;
}
