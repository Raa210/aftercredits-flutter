import 'package:aftercredits/core/constants/api_constants.dart';

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

  // ─── Detail-only fields (nullable, only populated via getMovieDetailsRaw) ───
  final int? runtime; // durasi dalam menit
  final String? tagline;
  final String? status;
  final List<Map<String, dynamic>> genres; // [{id, name}, ...]

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
    this.runtime,
    this.tagline,
    this.status,
    this.genres = const [],
  });

  factory MovieModel.fromJson(Map<String, dynamic> json) {
    // Parse genres array (from detail response)
    final genresRaw = json['genres'] as List<dynamic>?;
    final List<Map<String, dynamic>> genresList = genresRaw
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ??
        [];

    // Parse genre_ids array (from list response)
    final genreIdsRaw = json['genre_ids'] as List<dynamic>?;
    final List<int> genreIdsList =
        genreIdsRaw?.map((e) => e as int).toList() ?? [];

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
      genreIds: genreIdsList,
      originalLanguage: json['original_language'] as String?,
      popularity: (json['popularity'] as num?)?.toDouble() ?? 0.0,
      adult: json['adult'] as bool? ?? false,
      runtime: json['runtime'] as int?,
      tagline: json['tagline'] as String?,
      status: json['status'] as String?,
      genres: genresList,
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

  /// Format runtime: "2j 15m"
  String? get runtimeFormatted {
    if (runtime == null || runtime! <= 0) return null;
    final h = runtime! ~/ 60;
    final m = runtime! % 60;
    if (h == 0) return '${m}m';
    if (m == 0) return '${h}j';
    return '${h}j ${m}m';
  }

  /// Semua genre names (dari `genres` list jika tersedia, fallback ke genreIds)
  List<String> get genreNames =>
      genres.map((g) => g['name'] as String? ?? '').where((n) => n.isNotEmpty).toList();

  @override
  String toString() => 'MovieModel(id: $id, title: $title, adult: $adult)';
}
