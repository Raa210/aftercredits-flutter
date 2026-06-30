import '../core/constants/api_constants.dart';

class MovieModel {
  final int id;
  final String title;
  final String? originalTitle;
  final String? overview;
  final String? posterPath;
  final String? backdropPath;
  final double voteAverage;
  final int voteCount;
  final String? releaseDate;
  final List<int> genreIds;
  final String? originalLanguage;
  final double popularity;
  final bool adult;

  const MovieModel({
    required this.id,
    required this.title,
    this.originalTitle,
    this.overview,
    this.posterPath,
    this.backdropPath,
    required this.voteAverage,
    required this.voteCount,
    this.releaseDate,
    this.genreIds = const [],
    this.originalLanguage,
    required this.popularity,
    this.adult = false,
  });

  factory MovieModel.fromJson(Map<String, dynamic> json) {
    return MovieModel(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? json['name'] as String? ?? '',
      originalTitle: json['original_title'] as String?,
      overview: json['overview'] as String?,
      posterPath: json['poster_path'] as String?,
      backdropPath: json['backdrop_path'] as String?,
      voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 0.0,
      voteCount: json['vote_count'] as int? ?? 0,
      releaseDate: json['release_date'] as String?,
      genreIds: (json['genre_ids'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [],
      originalLanguage: json['original_language'] as String?,
      popularity: (json['popularity'] as num?)?.toDouble() ?? 0.0,
      adult: json['adult'] as bool? ?? false,
    );
  }

  // ─── Computed properties ──────────────────────────────────

  String? get posterUrl =>
      posterPath != null ? '${ApiConstants.posterMedium}$posterPath' : null;

  String? get posterSmallUrl =>
      posterPath != null ? '${ApiConstants.posterSmall}$posterPath' : null;

  String? get posterLargeUrl =>
      posterPath != null ? '${ApiConstants.posterLarge}$posterPath' : null;

  String? get backdropUrl =>
      backdropPath != null ? '${ApiConstants.backdropMedium}$backdropPath' : null;

  String? get backdropFullUrl =>
      backdropPath != null ? '${ApiConstants.backdropFull}$backdropPath' : null;

  String get year =>
      releaseDate != null && releaseDate!.length >= 4
          ? releaseDate!.substring(0, 4)
          : '-';

  String get ratingFormatted => voteAverage.toStringAsFixed(1);

  bool get isHiddenGem => voteAverage >= 7.5 && voteCount < 2000;

  @override
  String toString() => 'MovieModel(id: $id, title: $title, adult: $adult)';
}
