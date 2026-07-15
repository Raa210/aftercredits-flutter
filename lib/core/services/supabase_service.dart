import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase project configuration.
///
/// ─────────────────────────────────────────────────────────
/// SUPABASE DASHBOARD SETUP (run before first launch):
///
/// 1. SQL Editor → paste and run:
///    CREATE TABLE public.profiles (
///      id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
///      username TEXT UNIQUE NOT NULL,
///      avatar_url TEXT,
///      favorite_genre_ids INTEGER[] DEFAULT ARRAY[]::INTEGER[],
///      favorite_movie_ids INTEGER[] DEFAULT ARRAY[]::INTEGER[],
///      onboarding_complete BOOLEAN DEFAULT FALSE,
///      created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
///    );
///    ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
///    CREATE POLICY "Users can view own profile" ON public.profiles
///      FOR SELECT TO authenticated USING (auth.uid() = id);
///    CREATE POLICY "Users can insert own profile" ON public.profiles
///      FOR INSERT TO authenticated WITH CHECK (auth.uid() = id);
///    CREATE POLICY "Users can update own profile" ON public.profiles
///      FOR UPDATE TO authenticated USING (auth.uid() = id);
///
/// 2. Storage → create bucket named "avatars" → set as Public
///
/// 3. Authentication → Sign In Methods → Email → enable "Email OTP"
///    (so signup sends a 6-digit code, not a magic link)
///
/// 4. Authentication → URL Configuration:
///    Site URL:      com.example.aftercredits://login-callback
///    Redirect URLs: com.example.aftercredits://login-callback
///
/// 5. Authentication → Providers → Google → Enable
///    Client ID:     your_web_oauth_client_id (from Google Cloud Console)
///    Client Secret: your_client_secret
/// ─────────────────────────────────────────────────────────
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
