import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/user_profile_model.dart';
import 'supabase_service.dart';

/// Service for CRUD operations on the Supabase `profiles` table
/// and avatar uploads to Supabase Storage.
class UserProfileService {
  static final UserProfileService _instance = UserProfileService._internal();
  factory UserProfileService() => _instance;
  UserProfileService._internal();

  // ─── Read ─────────────────────────────────────────────────

  /// Fetch the profile for [userId]. Returns null if not found.
  Future<UserProfileModel?> getProfile(String userId) async {
    try {
      final data = await supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      if (data == null) return null;
      return UserProfileModel.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  // ─── Username check ───────────────────────────────────────

  /// Returns true if [username] is not taken.
  Future<bool> isUsernameAvailable(String username) async {
    try {
      final data = await supabase
          .from('profiles')
          .select('id')
          .eq('username', username.toLowerCase().trim())
          .maybeSingle();
      return data == null;
    } catch (_) {
      return true; // Assume available on network error, server will reject on save
    }
  }

  // ─── Avatar upload ────────────────────────────────────────

  /// Uploads avatar [bytes] to Supabase Storage and returns the public URL.
  ///
  /// Requires the "avatars" bucket to exist with public access.
  Future<String> uploadAvatar({
    required String userId,
    required Uint8List bytes,
    required String extension,
  }) async {
    final safeExt = extension.toLowerCase() == 'jpg' ? 'jpeg' : extension.toLowerCase();
    final path = '$userId/avatar.$safeExt';

    await supabase.storage.from('avatars').uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            upsert: true,
            contentType: 'image/$safeExt',
          ),
        );

    return supabase.storage.from('avatars').getPublicUrl(path);
  }

  // ─── Create / Update ──────────────────────────────────────

  /// Creates or updates the user's profile row and marks onboarding as complete.
  Future<void> saveProfile({
    required String userId,
    required String username,
    String? avatarUrl,
    required List<int> favoriteGenreIds,
    required List<int> favoriteMovieIds,
  }) async {
    await supabase.from('profiles').upsert({
      'id': userId,
      'username': username.toLowerCase().trim(),
      'avatar_url': avatarUrl,
      'favorite_genre_ids': favoriteGenreIds,
      'favorite_movie_ids': favoriteMovieIds,
      'onboarding_complete': true,
      'created_at': DateTime.now().toIso8601String(),
    });
  }
}
