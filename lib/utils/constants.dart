import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase configuration sourced from `.env`.
///
/// Expected keys:
/// - SUPABASE_URL
/// - SUPABASE_ANON_KEY
String get supabaseUrl => (dotenv.env['SUPABASE_URL'] ?? '').trim();
String get supabaseAnonKey => (dotenv.env['SUPABASE_ANON_KEY'] ?? '').trim();

bool get isSupabaseConfigured => supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

// Supabase client getter (valid after Supabase.initialize)
SupabaseClient get supabase => Supabase.instance.client;
