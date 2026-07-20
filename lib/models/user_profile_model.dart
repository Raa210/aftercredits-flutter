/// Data model for a user's profile stored in Supabase `profiles` table.
class UserProfileModel {
  final String id;
  final String username;
  final String? bio;
  final String? avatarUrl;
  final List<int> favoriteGenreIds;
  final List<int> favoriteMovieIds;
  final bool onboardingComplete;
  final DateTime createdAt;

  const UserProfileModel({
    required this.id,
    required this.username,
    this.bio,
    this.avatarUrl,
    this.favoriteGenreIds = const [],
    this.favoriteMovieIds = const [],
    this.onboardingComplete = false,
    required this.createdAt,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['id'] as String,
      username: json['username'] as String,
      bio: json['bio'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      favoriteGenreIds: (json['favorite_genre_ids'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [],
      favoriteMovieIds: (json['favorite_movie_ids'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [],
      onboardingComplete: json['onboarding_complete'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        if (bio != null) 'bio': bio,
        'avatar_url': avatarUrl,
        'favorite_genre_ids': favoriteGenreIds,
        'favorite_movie_ids': favoriteMovieIds,
        'onboarding_complete': onboardingComplete,
      };

  /// Display name — prefers username, falls back to 'User'
  String get displayName => username.isNotEmpty ? '@$username' : 'User';
}

