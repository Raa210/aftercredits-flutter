import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../../models/movie_model.dart';

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
        extra: {'language': 'id-ID', 'page': '$page'});
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

    final d = await _get(ApiConstants.discoverBase, extra: extra);
    return _parse(d);
  }

  /// Hidden gems: rating tinggi, vote sedikit
  Future<List<MovieModel>> getHiddenGems() async {
    final d = await _get(
      ApiConstants.discoverBase,
      extra: {
        'language': 'id-ID',
        'sort_by': 'vote_average.desc',
        'vote_count.gte': '100',
        'vote_count.lte': '3000',
        'vote_average.gte': '7.5',
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

  // ─── Parser ───────────────────────────────────────────────

  List<MovieModel> _parse(Map<String, dynamic>? data) {
    if (data == null) return [];
    final results = data['results'] as List<dynamic>? ?? [];
    return results
        .map((e) => MovieModel.fromJson(e as Map<String, dynamic>))
        .where((m) => m.posterPath != null)
        .toList();
  }
}
