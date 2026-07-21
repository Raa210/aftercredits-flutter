/// =====================================================================
///  TMDB API Configuration
/// =====================================================================

class ApiConstants {
  // ─── TMDB Credentials ──────────────────────────────────
  static const String tmdbAccessToken =
      'eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiI4OGZlMjZkZGQ3ODFiNGUwZmQ0MGE4MThiZjAzYzQ1NSIsIm5iZiI6MTc3OTE1NTgzOS4zNjMwMDAyLCJzdWIiOiI2YTBiYzM3ZjgyMjFhM2VkM2Y0NjZkYzAiLCJzY29wZXMiOlsiYXBpX3JlYWQiXSwidmVyc2lvbiI6MX0.v3Us_FntbthPkZxWT10tya4_Lfmb_bg2-QwWc17TzwE';

  // ─── Base URLs ──────────────────────────────────────────
  static const String tmdbBaseUrl = 'https://api.themoviedb.org/3';
  static const String imageBaseUrl = 'https://image.tmdb.org/t/p';

  // ─── Image Sizes ────────────────────────────────────────
  static const String posterSmall = '$imageBaseUrl/w185';
  static const String posterMedium = '$imageBaseUrl/w342';
  static const String posterLarge = '$imageBaseUrl/w500';
  static const String backdropMedium = '$imageBaseUrl/w780';
  static const String backdropFull = '$imageBaseUrl/original';

  // ─── Endpoints ──────────────────────────────────────────
  static const String trendingWeek = '$tmdbBaseUrl/trending/movie/week';
  static const String nowPlaying = '$tmdbBaseUrl/movie/now_playing';
  static const String popular = '$tmdbBaseUrl/movie/popular';
  static const String topRated = '$tmdbBaseUrl/movie/top_rated';
  static const String upcoming = '$tmdbBaseUrl/movie/upcoming';
  static const String discoverBase = '$tmdbBaseUrl/discover/movie';


  static String movieDetails(int id) => '$tmdbBaseUrl/movie/$id';
  static String movieVideos(int id) => '$tmdbBaseUrl/movie/$id/videos';
  static String movieCredits(int id) => '$tmdbBaseUrl/movie/$id/credits';
  static String searchMovies(String query) =>
      '$tmdbBaseUrl/search/movie?query=${Uri.encodeComponent(query)}';
  static String discoverByGenre(int genreId) =>
      '$tmdbBaseUrl/discover/movie?with_genres=$genreId&sort_by=popularity.desc';

  // ─── Genre IDs ──────────────────────────────────────────
  static const Map<String, int> genreIds = {
    'Aksi': 28,
    'Drama': 18,
    'Sci-Fi': 878,
    'Komedi': 35,
    'Thriller': 53,
    'Horor': 27,
    'Romansa': 10749,
    'Animasi': 16,
    'Dokumenter': 99,
    'Kriminal': 80,
  };

  // ─── Helper ─────────────────────────────────────────────
  static Map<String, String> get authHeaders => {
    'Authorization': 'Bearer $tmdbAccessToken',
    'Accept': 'application/json',
  };

  static bool get isTokenSet =>
      tmdbAccessToken.isNotEmpty &&
      tmdbAccessToken != 'MASUKKAN_TOKEN_TMDB_DI_SINI';
}
