import 'package:flutter/material.dart';
import 'package:aftercredits/core/theme/app_theme.dart';
import 'package:aftercredits/core/services/tmdb_service.dart';
import 'package:aftercredits/models/movie_model.dart';
import 'package:aftercredits/features/movie_detail/movie_detail_screen.dart';

// ─── Genre items ──────────────────────────────────────────────
class _GenreItem {
  final String name;
  final int? id;
  const _GenreItem(this.name, this.id);
}

// ═════════════════════════════════════════════════════════════
// SeeAllMoviesScreen
// ═════════════════════════════════════════════════════════════

enum SectionType { popular, nowPlaying, hiddenGems }

class SeeAllMoviesScreen extends StatefulWidget {
  final String title;
  final List<MovieModel> initialMovies;
  final Color accentColor;
  final bool enableGenreFilter;
  final SectionType sectionType;

  const SeeAllMoviesScreen({
    super.key,
    required this.title,
    required this.initialMovies,
    required this.accentColor,
    this.enableGenreFilter = false,
    this.sectionType = SectionType.popular,
  });

  @override
  State<SeeAllMoviesScreen> createState() => _SeeAllMoviesScreenState();
}

class _SeeAllMoviesScreenState extends State<SeeAllMoviesScreen> {
  final TmdbService _tmdb = TmdbService();
  late List<MovieModel> _movies;
  int _selectedGenreIndex = 0;
  bool _loading = false;

  static const List<_GenreItem> _genres = [
    _GenreItem('Semua', null),
    _GenreItem('Aksi', 28),
    _GenreItem('Drama', 18),
    _GenreItem('Sci-Fi', 878),
    _GenreItem('Komedi', 35),
    _GenreItem('Thriller', 53),
    _GenreItem('Horor', 27),
    _GenreItem('Animasi', 16),
    _GenreItem('Kriminal', 80),
    _GenreItem('Romansa', 10749),
  ];

  @override
  void initState() {
    super.initState();
    _movies = List.from(widget.initialMovies);
  }

  Future<void> _loadByGenre(int index) async {
    if (!widget.enableGenreFilter) return;
    setState(() {
      _selectedGenreIndex = index;
      _loading = true;
    });

    final genreId = _genres[index].id;
    List<MovieModel> results;
    if (genreId == null) {
      results = await _tmdb.getHiddenGems();
    } else {
      results = await _tmdb.getByGenre(
        genreId,
        sortBy: 'vote_average.desc',
        minVoteCount: 100,
        maxVoteCount: 3000,
        minVoteAverage: 7.0,
      );
    }

    if (!mounted) return;
    setState(() {
      _movies = results;
      _loading = false;
    });
  }

  void _openDetail(MovieModel movie) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => MovieDetailScreen(movie: movie)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.darkPrimary,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.darkSecondary,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: AppColors.textPrimary, size: 16),
          ),
        ),
        title: Text(
          widget.title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),
      body: Column(
        children: [
          // Genre filter pills (hanya untuk Hidden Gems)
          if (widget.enableGenreFilter) ...[
            const SizedBox(height: 4),
            SizedBox(
              height: 36,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: _genres.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final selected = i == _selectedGenreIndex;
                  return GestureDetector(
                    onTap: () => _loadByGenre(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                      decoration: BoxDecoration(
                        color: selected ? widget.accentColor : AppColors.darkTertiary,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected ? widget.accentColor : AppColors.border,
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        _genres[i].name,
                        style: TextStyle(
                          color: selected ? Colors.white : AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ] else
            const SizedBox(height: 8),

          // Content
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.accentRed),
                  )
                : _movies.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.movie_outlined, color: AppColors.textMuted, size: 40),
                            SizedBox(height: 12),
                            Text(
                              'Tidak ada film',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 10,
                          childAspectRatio: 0.58,
                        ),
                        itemCount: _movies.length,
                        itemBuilder: (_, i) {
                          final movie = _movies[i];
                          return _MovieGridCard(
                            movie: movie,
                            accentColor: widget.accentColor,
                            onTap: () => _openDetail(movie),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════
// Movie Grid Card
// ═════════════════════════════════════════════════════════════

class _MovieGridCard extends StatelessWidget {
  final MovieModel movie;
  final Color accentColor;
  final VoidCallback onTap;

  const _MovieGridCard({
    required this.movie,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  movie.posterUrl != null
                      ? Image.network(
                          movie.posterUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: AppColors.darkTertiary,
                            child: const Icon(Icons.movie_outlined,
                                color: AppColors.textMuted, size: 24),
                          ),
                        )
                      : Container(
                          color: AppColors.darkTertiary,
                          child: const Icon(Icons.movie_outlined,
                              color: AppColors.textMuted, size: 24),
                        ),

                  // Rating badge
                  Positioned(
                    top: 5,
                    left: 5,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(185),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star_rounded, color: accentColor, size: 9),
                          const SizedBox(width: 2),
                          Text(
                            movie.ratingFormatted,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            movie.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            movie.year,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
