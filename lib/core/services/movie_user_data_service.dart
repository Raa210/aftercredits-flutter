import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aftercredits/models/movie_review_model.dart';

/// Service untuk menyimpan dan membaca data interaksi user terhadap film:
/// - Watched history
/// - Watchlist
/// - Reviews
///
/// Semua data disimpan lokal via SharedPreferences (JSON-encoded).
class MovieUserDataService {
  static final MovieUserDataService _instance = MovieUserDataService._internal();
  factory MovieUserDataService() => _instance;
  MovieUserDataService._internal();

  // ─── Keys ────────────────────────────────────────────────
  static const _keyWatched = 'user_watched_ids';
  static const _keyWatchlist = 'user_watchlist_ids';
  static const _keyReviews = 'user_movie_reviews';

  // ─── Watched ─────────────────────────────────────────────

  Future<List<int>> getWatchedIds() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_keyWatched) ?? [];
    return raw.map((e) => int.tryParse(e) ?? 0).where((e) => e != 0).toList();
  }

  Future<bool> isWatched(int movieId) async {
    final ids = await getWatchedIds();
    return ids.contains(movieId);
  }

  /// Toggle watched status. Returns true jika sekarang di-watched, false jika di-unwatched.
  Future<bool> toggleWatched(int movieId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_keyWatched) ?? [];
    final ids = raw.map((e) => int.tryParse(e) ?? 0).where((e) => e != 0).toList();

    if (ids.contains(movieId)) {
      ids.remove(movieId);
      await prefs.setStringList(_keyWatched, ids.map((e) => e.toString()).toList());
      return false;
    } else {
      ids.add(movieId);
      await prefs.setStringList(_keyWatched, ids.map((e) => e.toString()).toList());
      return true;
    }
  }

  Future<int> getWatchedCount() async {
    final ids = await getWatchedIds();
    return ids.length;
  }

  // ─── Watchlist ────────────────────────────────────────────

  Future<List<int>> getWatchlistIds() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_keyWatchlist) ?? [];
    return raw.map((e) => int.tryParse(e) ?? 0).where((e) => e != 0).toList();
  }

  Future<bool> isInWatchlist(int movieId) async {
    final ids = await getWatchlistIds();
    return ids.contains(movieId);
  }

  /// Toggle watchlist. Returns true jika sekarang di-watchlist, false jika dihapus.
  Future<bool> toggleWatchlist(int movieId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_keyWatchlist) ?? [];
    final ids = raw.map((e) => int.tryParse(e) ?? 0).where((e) => e != 0).toList();

    if (ids.contains(movieId)) {
      ids.remove(movieId);
      await prefs.setStringList(_keyWatchlist, ids.map((e) => e.toString()).toList());
      return false;
    } else {
      ids.add(movieId);
      await prefs.setStringList(_keyWatchlist, ids.map((e) => e.toString()).toList());
      return true;
    }
  }

  Future<int> getWatchlistCount() async {
    final ids = await getWatchlistIds();
    return ids.length;
  }

  // ─── Reviews ─────────────────────────────────────────────

  Future<Map<int, MovieReview>> getAllReviews() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyReviews);
    if (raw == null || raw.isEmpty) return {};

    try {
      final Map<String, dynamic> decoded = json.decode(raw) as Map<String, dynamic>;
      return decoded.map((key, value) {
        final movieId = int.parse(key);
        final review = MovieReview.fromJson(value as Map<String, dynamic>);
        return MapEntry(movieId, review);
      });
    } catch (_) {
      return {};
    }
  }

  Future<MovieReview?> getReview(int movieId) async {
    final all = await getAllReviews();
    return all[movieId];
  }

  Future<void> saveReview({
    required int movieId,
    required double rating,
    required String text,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final all = await getAllReviews();

    all[movieId] = MovieReview(
      movieId: movieId,
      rating: rating.clamp(0.5, 5.0),
      text: text.trim(),
      createdAt: DateTime.now(),
    );

    final encoded = json.encode(all.map(
      (key, value) => MapEntry(key.toString(), value.toJson()),
    ));
    await prefs.setString(_keyReviews, encoded);
  }

  Future<void> deleteReview(int movieId) async {
    final prefs = await SharedPreferences.getInstance();
    final all = await getAllReviews();
    all.remove(movieId);

    final encoded = json.encode(all.map(
      (key, value) => MapEntry(key.toString(), value.toJson()),
    ));
    await prefs.setString(_keyReviews, encoded);
  }

  Future<bool> hasReview(int movieId) async {
    final review = await getReview(movieId);
    return review != null;
  }

  Future<int> getReviewCount() async {
    final all = await getAllReviews();
    return all.length;
  }

  /// Rata-rata rating dari semua review user
  Future<double> getAverageRating() async {
    final all = await getAllReviews();
    if (all.isEmpty) return 0.0;
    final total = all.values.fold(0.0, (sum, r) => sum + r.rating);
    return total / all.length;
  }

  // ─── Movie Taste (genre dari watched history) ─────────────

  /// Simpan genre IDs dari film yang sudah ditonton
  static const _keyWatchedGenreMap = 'user_watched_genre_map';

  Future<void> saveMovieGenres(int movieId, List<int> genreIds) async {
    if (genreIds.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyWatchedGenreMap);
    Map<String, dynamic> map = {};
    if (raw != null && raw.isNotEmpty) {
      try {
        map = json.decode(raw) as Map<String, dynamic>;
      } catch (_) {}
    }
    map[movieId.toString()] = genreIds;
    await prefs.setString(_keyWatchedGenreMap, json.encode(map));
  }

  /// Ambil genre count dari watched history (untuk Movie Taste Profile)
  Future<Map<int, int>> getWatchedGenreCounts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyWatchedGenreMap);
    if (raw == null || raw.isEmpty) return {};

    try {
      final Map<String, dynamic> map = json.decode(raw) as Map<String, dynamic>;
      final watchedIds = await getWatchedIds();
      final counts = <int, int>{};

      for (final movieIdStr in map.keys) {
        final movieId = int.tryParse(movieIdStr);
        if (movieId == null || !watchedIds.contains(movieId)) continue;
        final genres = (map[movieIdStr] as List<dynamic>?)
            ?.map((e) => e as int)
            .toList() ?? [];
        for (final gId in genres) {
          counts[gId] = (counts[gId] ?? 0) + 1;
        }
      }

      return counts;
    } catch (_) {
      return {};
    }
  }
}
