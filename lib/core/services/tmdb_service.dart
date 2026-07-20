import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:aftercredits/core/constants/api_constants.dart';
import 'package:aftercredits/models/movie_model.dart';
import 'package:aftercredits/models/cast_model.dart';

class TmdbService {
  static final TmdbService _instance = TmdbService._internal();
  factory TmdbService() => _instance;
  TmdbService._internal();

  // ─── Internal GET ─────────────────────────────────────────

  Future<Map<String, dynamic>?> _get(String url,
      {Map<String, String>? extra}) async {
    if (!ApiConstants.isTokenSet) return null;

    Uri uri = Uri.parse(url);
    if (extra != null) {
      final params = {...uri.queryParameters, ...extra};
      uri = uri.replace(queryParameters: params);
    }

    try {
      final res = await http
          .get(uri, headers: ApiConstants.authHeaders)
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        return json.decode(res.body) as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // ─── Public endpoints ─────────────────────────────────────

  Future<List<MovieModel>> getTrendingWeek({int page = 1}) async {
    final d = await _get(ApiConstants.trendingWeek,
        extra: {'language': 'id-ID', 'page': '$page'});
    return _parse(d);
  }

  Future<List<MovieModel>> getNowPlaying({int page = 1}) async {
    final d = await _get(ApiConstants.nowPlaying,
        extra: {'language': 'id-ID', 'page': '$page'});
    return _parse(d);
  }

  Future<List<MovieModel>> getPopular({int page = 1}) async {
    final d = await _get(ApiConstants.popular,
        extra: {'language': 'id-ID', 'page': '$page'});
    return _parse(d);
  }

  Future<List<MovieModel>> getTopRated({int page = 1}) async {
    final d = await _get(ApiConstants.topRated,
        extra: {'language': 'id-ID', 'page': '$page'});
    return _parse(d);
  }

  Future<List<MovieModel>> getUpcoming({int page = 1}) async {
    final d = await _get(ApiConstants.upcoming,
        extra: {'language': 'id-ID', 'page': '$page'});
    return _parse(d);
  }

  Future<List<MovieModel>> searchMovies(String query, {int page = 1}) async {
    final d = await _get(ApiConstants.searchMovies(query),
        extra: {'language': 'id-ID', 'page': '$page', 'include_adult': 'false'});
    return _parse(d);
  }

  /// Film berdasarkan genre dengan filter tambahan
  Future<List<MovieModel>> getByGenre(
    int genreId, {
    int page = 1,
    String sortBy = 'popularity.desc',
    int? minVoteCount,
    int? maxVoteCount,
    double? minVoteAverage,
  }) async {
    final extra = <String, String>{
      'language': 'id-ID',
      'page': '$page',
      'with_genres': '$genreId',
      'sort_by': sortBy,
    };
    if (minVoteCount != null) {
      extra['vote_count.gte'] = '$minVoteCount';
    }
    if (maxVoteCount != null) {
      extra['vote_count.lte'] = '$maxVoteCount';
    }
    if (minVoteAverage != null) {
      extra['vote_average.gte'] = '$minVoteAverage';
    }
    extra['include_adult'] = 'false';

    final d = await _get(ApiConstants.discoverBase, extra: extra);
    return _parse(d);
  }

  /// Film berdasarkan beberapa genre (OR / pipe separated)
  Future<List<MovieModel>> getMoviesByGenres(
    List<int> genreIds, {
    int page = 1,
    String sortBy = 'popularity.desc',
  }) async {
    if (genreIds.isEmpty) return getTopRated(page: page);
    final extra = <String, String>{
      'language': 'id-ID',
      'page': '$page',
      'with_genres': genreIds.join('|'),
      'sort_by': sortBy,
      'vote_count.gte': '50',
      'include_adult': 'false',
    };
    final d = await _get(ApiConstants.discoverBase, extra: extra);
    return _parse(d);
  }

  /// Hidden gems: rating tinggi, vote cukup, diurutkan popularitas agar film berkualitas & aman
  Future<List<MovieModel>> getHiddenGems() async {
    final d = await _get(
      ApiConstants.discoverBase,
      extra: {
        'language': 'id-ID',
        'sort_by': 'vote_average.desc',
        'vote_count.gte': '300',
        'vote_count.lte': '5000',
        'vote_average.gte': '7.5',
        'include_adult': 'false',
        'without_genres': '10749',
      },
    );
    return _parse(d);
  }

  Future<MovieModel?> getMovieDetails(int id) async {
    final d = await _get(
      ApiConstants.movieDetails(id),
      extra: {
        'language': 'id-ID',
        'append_to_response': 'credits,videos',
      },
    );
    if (d == null) return null;
    return MovieModel.fromJson(d);
  }

  /// Mengembalikan raw map dengan credits dan videos untuk detail page.
  Future<Map<String, dynamic>?> getMovieDetailsRaw(int id) async {
    final data = await _get(
      ApiConstants.movieDetails(id),
      extra: {
        'language': 'id-ID',
        'append_to_response': 'credits,videos',
        'include_video_language': 'id,en,null',
      },
    );

    if (data != null) {
      final overview = data['overview'] as String?;
      final credits = data['credits'] as Map<String, dynamic>?;
      final cast = credits?['cast'] as List<dynamic>? ?? [];

      // Jika sinopsis kosong atau tidak ada cast, fetch versi en-US sebagai fallback
      if ((overview == null || overview.isEmpty) || cast.isEmpty) {
        final enData = await _get(
          ApiConstants.movieDetails(id),
          extra: {
            'language': 'en-US',
            'append_to_response': 'credits,videos',
            'include_video_language': 'id,en,null',
          },
        );

        if (enData != null) {
          if (overview == null || overview.isEmpty) {
            data['overview'] = enData['overview'];
          }
          if (cast.isEmpty) {
            data['credits'] = enData['credits'];
          }
        }
      }
    }
    
    return data;
  }

  /// Mengambil daftar cast dari raw detail response.
  List<CastModel> parseCast(Map<String, dynamic> raw) {
    final credits = raw['credits'] as Map<String, dynamic>?;
    if (credits == null) return [];
    final castRaw = credits['cast'] as List<dynamic>? ?? [];
    return castRaw
        .map((e) => CastModel.fromJson(e as Map<String, dynamic>))
        .where((c) => c.profilePath != null)
        .take(20)
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }

  /// Mengambil key YouTube trailer utama.
  /// Urutan prioritas: Official Trailer → Trailer → Teaser
  String? parseTrailerKey(Map<String, dynamic> raw) {
    final videos = raw['videos'] as Map<String, dynamic>?;
    if (videos == null) return null;
    final results = videos['results'] as List<dynamic>? ?? [];

    final youtubeVideos = results
        .map((e) => e as Map<String, dynamic>)
        .where((v) => v['site'] == 'YouTube')
        .toList();

    // Cari Official Trailer terlebih dahulu
    Map<String, dynamic>? trailer;
    trailer = youtubeVideos.where((v) {
      final name = (v['name'] as String? ?? '').toLowerCase();
      return v['type'] == 'Trailer' && name.contains('official');
    }).firstOrNull;

    trailer ??= youtubeVideos.where((v) => v['type'] == 'Trailer').firstOrNull;
    trailer ??= youtubeVideos.where((v) => v['type'] == 'Teaser').firstOrNull;
    trailer ??= youtubeVideos.firstOrNull;

    return trailer?['key'] as String?;
  }

  // ─── Parser ───────────────────────────────────────────────

  List<MovieModel> _parse(Map<String, dynamic>? data) {
    if (data == null) return [];
    final results = data['results'] as List<dynamic>? ?? [];
    return results
        .map((e) => MovieModel.fromJson(e as Map<String, dynamic>))
        .where((m) => m.posterPath != null && _isSafeAndCleanMovie(m))
        .toList();
  }

  bool _isSafeAndCleanMovie(MovieModel m) {
    if (m.adult) return false;

    final titleLower = m.title.toLowerCase();
    final origLower = (m.originalTitle ?? '').toLowerCase();
    final overviewLower = (m.overview ?? '').toLowerCase();

    // Blacklist kata kunci tidak senonoh / eksplisit / erotis yang lolos include_adult dari TMDB
    const bannedKeywords = [
      'nude',
      'nudity',
      'sex',
      'erotic',
      'erotica',
      'porn',
      'porno',
      'xxx',
      'emmanuelle',
      'kama sutra',
      'sensual',
      'lust',
      'voyeur',
      'seduction',
      'seductress',
      'taboo',
      'nympho',
      'incest',
      'orgasm',
      'playboy',
      'penthouse',
      'fetish',
      'peep show',
      'whore',
      'slut',
      'brothel',
    ];

    for (final kw in bannedKeywords) {
      if (titleLower.contains(kw) || origLower.contains(kw)) {
        return false;
      }
    }

    const bannedOverview = [
      'erotic movie',
      'erotic film',
      'softcore',
      'hardcore porn',
      'adult film',
      'sex industry',
    ];
    for (final kw in bannedOverview) {
      if (overviewLower.contains(kw)) {
        return false;
      }
    }

    return true;
  }
}
