import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Environment: 'test' (local) vs 'prod' (deployed to Vercel).
/// Drives which Supabase project credentials to use.
const String appEnvironment =
    String.fromEnvironment('APP_ENV', defaultValue: 'prod');

const String _supabaseUrlOverride =
    String.fromEnvironment('SUPABASE_URL', defaultValue: '');
const String _supabaseAnonKeyOverride =
    String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');
const String _supabaseUrlTestOverride =
    String.fromEnvironment('SUPABASE_URL_TEST', defaultValue: '');
const String _supabaseAnonKeyTestOverride =
    String.fromEnvironment('SUPABASE_ANON_KEY_TEST', defaultValue: '');

String _safeEnv(String key) {
  try {
    return (dotenv.env[key] ?? '').trim();
  } catch (_) {
    return '';
  }
}

/// Supabase URL for the current environment.
/// - test: SUPABASE_URL_TEST (or SUPABASE_URL fallback)
/// - prod: SUPABASE_URL
String get safeSupabaseUrl {
  if (appEnvironment == 'test') {
    final url = _supabaseUrlTestOverride.isNotEmpty
        ? _supabaseUrlTestOverride
        : _safeEnv('SUPABASE_URL_TEST');
    if (url.isNotEmpty) return url;
  }
  return _supabaseUrlOverride.isNotEmpty
      ? _supabaseUrlOverride
      : _safeEnv('SUPABASE_URL');
}

/// Supabase anon key for the current environment.
/// - test: SUPABASE_ANON_KEY_TEST (or SUPABASE_ANON_KEY fallback)
/// - prod: SUPABASE_ANON_KEY
String get safeSupabaseAnonKey {
  if (appEnvironment == 'test') {
    final key = _supabaseAnonKeyTestOverride.isNotEmpty
        ? _supabaseAnonKeyTestOverride
        : _safeEnv('SUPABASE_ANON_KEY_TEST');
    if (key.isNotEmpty) return key;
  }
  return _supabaseAnonKeyOverride.isNotEmpty
      ? _supabaseAnonKeyOverride
      : _safeEnv('SUPABASE_ANON_KEY');
}

String get supabaseUrl => safeSupabaseUrl;
String get supabaseAnonKey => safeSupabaseAnonKey;

bool get isSupabaseConfigured =>
    safeSupabaseUrl.isNotEmpty && safeSupabaseAnonKey.isNotEmpty;

/// True when running locally (test Supabase project).
bool get isTest => appEnvironment == 'test';

/// True when deployed to Vercel (prod Supabase project).
bool get isProd => appEnvironment == 'prod';

// Supabase client getter (valid after Supabase.initialize)
SupabaseClient get supabase => Supabase.instance.client;
