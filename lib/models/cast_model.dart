import 'package:aftercredits/core/constants/api_constants.dart';

/// Model untuk data cast/pemain film dari TMDB API.
class CastModel {
  final int id;
  final String name;
  final String? character;
  final String? profilePath;
  final int order;

  const CastModel({
    required this.id,
    required this.name,
    this.character,
    this.profilePath,
    this.order = 0,
  });

  factory CastModel.fromJson(Map<String, dynamic> json) {
    return CastModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      character: json['character'] as String?,
      profilePath: json['profile_path'] as String?,
      order: json['order'] as int? ?? 0,
    );
  }

  /// URL foto profil aktor (w185)
  String? get profileUrl =>
      profilePath != null ? '${ApiConstants.posterSmall}$profilePath' : null;
}
