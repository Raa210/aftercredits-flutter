import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase project configuration.
/// 
class SupabaseConfig {
  static const String url = 'https://fkzbivfzyvnlmhzfcsse.supabase.co';

  /// Publishable key (new format, preferred over anonKey in supabase_flutter v2.8+)
  static const String publishableKey =
      'sb_publishable_xV2K5kf9-jut8RU5QsHlEQ_J9EtIYit';

  /// JWT anon key (fallback if publishableKey is not accepted)
  static const String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9'
      '.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZremJpdmZ6eXZubG1oemZjc3NlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODM5Nzg3NzcsImV4cCI6MjA5OTU1NDc3N30'
      '.t9AAKGn2jAjtmZ7n49aUeriZGJi2GFqjdKVKrdFiCF8';
}

/// Top-level convenience getter for the Supabase client.
/// Usage: import 'supabase_service.dart'; then use `supabase.auth`, etc.
SupabaseClient get supabase => Supabase.instance.client;
