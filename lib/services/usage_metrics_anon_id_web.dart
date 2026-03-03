// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:convert';
import 'dart:html' as html;

/// Fetches anon_id from the Edge Function with credentials so the cookie is sent/set.
/// Returns the anon_id from the response body, or null on failure.
Future<String?> fetchAnonIdFromServer(String supabaseUrl, String anonKey) async {
  final url = '${supabaseUrl.replaceFirst(RegExp(r'/$'), '')}/functions/v1/get-anon-id';
  try {
    final request = await html.HttpRequest.request(
      url,
      method: 'GET',
      requestHeaders: {
        'Authorization': 'Bearer $anonKey',
        'Content-Type': 'application/json',
      },
      withCredentials: true,
    );
    if (request.status != 200) return null;
    final body = request.responseText?.trim();
    if (body == null || body.isEmpty) return null;
    final map = jsonDecode(body) as Map<String, dynamic>?;
    final anonId = map?['anon_id'] as String?;
    return (anonId != null && anonId.trim().isNotEmpty) ? anonId.trim() : null;
  } catch (_) {
    return null;
  }
}
