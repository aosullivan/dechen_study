import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase configuration sourced from `.env`.
///
/// Expected keys:
/// - SUPABASE_URL
/// - SUPABASE_ANON_KEY
String _safeEnv(String key) {
  try {
    return (dotenv.env[key] ?? '').trim();
  } catch (_) {
    return '';
  }
}

String get safeSupabaseUrl => _safeEnv('SUPABASE_URL');
String get safeSupabaseAnonKey => _safeEnv('SUPABASE_ANON_KEY');
String get supabaseUrl => safeSupabaseUrl;
String get supabaseAnonKey => safeSupabaseAnonKey;

bool get isSupabaseConfigured =>
    safeSupabaseUrl.isNotEmpty && safeSupabaseAnonKey.isNotEmpty;

// Supabase client getter (valid after Supabase.initialize)
SupabaseClient get supabase => Supabase.instance.client;
