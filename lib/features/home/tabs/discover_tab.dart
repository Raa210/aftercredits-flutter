import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:aftercredits/core/theme/app_theme.dart';
import 'package:aftercredits/core/services/tmdb_service.dart';
import 'package:aftercredits/core/constants/api_constants.dart';
import 'package:aftercredits/models/movie_model.dart';

class DiscoverTab extends StatefulWidget {
  const DiscoverTab({super.key});

  @override
  State<DiscoverTab> createState() => _DiscoverTabState();
}

class _DiscoverTabState extends State<DiscoverTab> {
  final TmdbService _tmdb = TmdbService();
  final PageController _heroController = PageController();
  Timer? _autoScrollTimer;

  int _selectedGenreIndex = 0;
  int _heroIndex = 0;

  List<MovieModel> _heroMovies = [];
  List<MovieModel> _popularMovies = [];
  List<MovieModel> _hiddenGems = [];
  bool _isLoading = true;
  bool _genreLoading = false;

  // Track which adult movies have been revealed (by id)
  final Set<int> _revealedAdult = {};

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
  ];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _heroController.dispose();
    super.dispose();
  }

  // ─── Data loading ─────────────────────────────────────────

  Future<void> _loadAll() async {
    if (!ApiConstants.isTokenSet) {
      setState(() => _isLoading = false);
      return;
    }
    setState(() {
      _isLoading = true;
      _revealedAdult.clear();
    });

    final results = await Future.wait([
      _tmdb.getNowPlaying(),
      _tmdb.getTrendingWeek(),
      _tmdb.getHiddenGems(),
    ]);

    if (!mounted) return;
    setState(() {
      _heroMovies = results[0].take(8).toList();
      _popularMovies = results[1].take(15).toList();
      _hiddenGems = results[2].take(12).toList();
      _isLoading = false;
      _heroIndex = 0;
    });
    _startAutoScroll();
  }

  Future<void> _loadByGenre(int index) async {
    if (!ApiConstants.isTokenSet) return;
    setState(() {
      _selectedGenreIndex = index;
      _genreLoading = true;
      _revealedAdult.clear();
    });

    final genreId = _genres[index].id;
    if (genreId == null) {
      // "Semua" — fetch default
      final results = await Future.wait([
        _tmdb.getTrendingWeek(),
        _tmdb.getHiddenGems(),
      ]);
      if (!mounted) return;
      setState(() {
        _popularMovies = results[0].take(15).toList();
        _hiddenGems = results[1].take(12).toList();
        _genreLoading = false;
      });
    } else {
      // specific genre — both sections filter by genre
      final results = await Future.wait([
        _tmdb.getByGenre(genreId, sortBy: 'popularity.desc'),
        _tmdb.getByGenre(genreId,
            sortBy: 'vote_average.desc',
            minVoteCount: 100,
            maxVoteCount: 3000,
            minVoteAverage: 7.0),
      ]);
      if (!mounted) return;
      setState(() {
        _popularMovies = results[0].take(15).toList();
        _hiddenGems = results[1].take(12).toList();
        _genreLoading = false;
      });
    }
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    if (_heroMovies.isEmpty) return;
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || _heroMovies.isEmpty) return;
      final next = (_heroIndex + 1) % _heroMovies.length;
      _heroController.animateToPage(
        next,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  void _toggleAdultReveal(int movieId) {
    setState(() {
      if (_revealedAdult.contains(movieId)) {
        _revealedAdult.remove(movieId);
      } else {
        _revealedAdult.add(movieId);
      }
    });
  }

  // ─── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkPrimary,
      body: RefreshIndicator(
        color: AppColors.accentRed,
        backgroundColor: AppColors.darkSecondary,
        onRefresh: _loadAll,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            // ── Hero carousel ──────────────────────────────
            SliverToBoxAdapter(child: _buildHero()),

            // ── Genre pills ────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: _buildGenrePills(),
              ),
            ),

            // ── Token warning ──────────────────────────────
            if (!ApiConstants.isTokenSet)
              SliverToBoxAdapter(child: _buildTokenWarning()),

            // ── Loading spinner ────────────────────────────
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.accentRed),
                ),
              )
            else ...[
              // ── Populer ────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 20, 0, 12),
                  child: _SectionHeader(
                    title: 'Populer Minggu Ini',
                    icon: Icons.local_fire_department_rounded,
                    iconColor: AppColors.accentRed,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: _genreLoading
                    ? const SizedBox(
                        height: 180,
                        child: Center(
                          child: CircularProgressIndicator(
                              color: AppColors.accentRed, strokeWidth: 2),
                        ),
                      )
                    : _buildMoviesRow(_popularMovies, accentColor: AppColors.star),
              ),

              // ── Hidden Gems ────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 24, 0, 12),
                  child: _SectionHeader(
                    title: 'Hidden Gems 💎',
                    icon: Icons.auto_awesome_rounded,
                    iconColor: const Color(0xFF7C3AED),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: _genreLoading
                    ? const SizedBox(
                        height: 180,
                        child: Center(
                          child: CircularProgressIndicator(
                              color: Color(0xFF7C3AED), strokeWidth: 2),
                        ),
                      )
                    : _buildMoviesRow(_hiddenGems,
                        accentColor: const Color(0xFF7C3AED)),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ],
        ),
      ),
    );
  }

  // ─── Hero ──────────────────────────────────────────────────

  Widget _buildHero() {
    if (_isLoading) {
      return const SizedBox(
        height: 300,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.accentRed),
        ),
      );
    }

    if (_heroMovies.isEmpty) {
      return _HeroPlaceholder();
    }

    return SizedBox(
      height: 300,
      child: Stack(
        children: [
          PageView.builder(
            controller: _heroController,
            onPageChanged: (i) => setState(() => _heroIndex = i),
            itemCount: _heroMovies.length,
            itemBuilder: (_, i) => _HeroCard(movie: _heroMovies[i]),
          ),

          // Progress dots
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_heroMovies.length, (i) {
                final active = i == _heroIndex;
                return GestureDetector(
                  onTap: () => _heroController.animateToPage(i,
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOut),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: active ? 20 : 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: active
                          ? AppColors.accentRed
                          : Colors.white.withAlpha(60),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Genre pills ───────────────────────────────────────────

  Widget _buildGenrePills() {
    return SizedBox(
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              decoration: BoxDecoration(
                color: selected ? AppColors.accentRed : AppColors.darkTertiary,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color:
                      selected ? AppColors.accentRed : AppColors.border,
                  width: 0.8,
                ),
              ),
              child: Text(
                _genres[i].name,
                style: TextStyle(
                  color: selected ? Colors.white : AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight:
                      selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── Movie row ─────────────────────────────────────────────

  Widget _buildMoviesRow(List<MovieModel> movies, {required Color accentColor}) {
    if (movies.isEmpty) {
      return const SizedBox(
        height: 180,
        child: Center(
          child: Text('Tidak ada film',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
        ),
      );
    }

    return SizedBox(
      height: 185,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: movies.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final movie = movies[i];
          return FadeInRight(
            delay: Duration(milliseconds: 40 * i),
            duration: const Duration(milliseconds: 350),
            child: SizedBox(
              width: 100,
              child: _MovieCardWidget(
                movie: movie,
                accentColor: accentColor,
                isRevealed: _revealedAdult.contains(movie.id),
                onTapReveal: () => _toggleAdultReveal(movie.id),
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── Token warning ────────────────────────────────────────

  Widget _buildTokenWarning() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF59E0B).withAlpha(70)),
      ),
      child: const Row(
        children: [
          Icon(Icons.key_rounded, color: Color(0xFFF59E0B), size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Tambahkan TMDB Token di\nlib/core/constants/api_constants.dart',
              style: TextStyle(
                color: Color(0xFFF59E0B),
                fontSize: 11,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════
// Genre data class
// ═════════════════════════════════════════════════════════════

class _GenreItem {
  final String name;
  final int? id;
  const _GenreItem(this.name, this.id);
}

// ═════════════════════════════════════════════════════════════
// Hero card — full backdrop + info overlay
// ═════════════════════════════════════════════════════════════

class _HeroCard extends StatelessWidget {
  final MovieModel movie;
  const _HeroCard({required this.movie});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Backdrop
        movie.backdropUrl != null
            ? _NetImg(url: movie.backdropUrl!, fit: BoxFit.cover)
            : Container(color: AppColors.darkSecondary),

        // Gradient
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0x33000000),
                Color(0xBB000000),
                AppColors.darkPrimary,
              ],
              stops: [0.0, 0.55, 1.0],
            ),
          ),
        ),

        // Left vignette
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Color(0x55000000), Colors.transparent],
            ),
          ),
        ),

        // Info bottom-left
        Positioned(
          bottom: 30,
          left: 16,
          right: 80,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.accentRed.withAlpha(35),
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: AppColors.accentRed.withAlpha(90)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: AppColors.accentRed,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      'Sekarang Tayang',
                      style: TextStyle(
                        color: AppColors.accentRed,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Title
              Text(
                movie.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1.15,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 5),

              // Meta
              Row(
                children: [
                  Text(movie.year,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 11)),
                  _dot(),
                  const Text('★',
                      style: TextStyle(color: AppColors.star, fontSize: 10)),
                  const SizedBox(width: 2),
                  Text(
                    movie.ratingFormatted,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  _dot(),
                  Text(
                    _fmtVotes(movie.voteCount),
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 10),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Buttons
              Row(
                children: [
                  _HeroBtn(
                    label: 'Tonton',
                    icon: Icons.play_arrow_rounded,
                    isPrimary: true,
                    onTap: () {},
                  ),
                  const SizedBox(width: 8),
                  _HeroBtn(
                    label: 'Watchlist',
                    icon: Icons.bookmark_add_outlined,
                    isPrimary: false,
                    onTap: () {},
                  ),
                ],
              ),
            ],
          ),
        ),

        // Poster thumb top-right
        if (movie.posterUrl != null)
          Positioned(
            bottom: 30,
            right: 16,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(130),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: _NetImg(url: movie.posterUrl!, width: 55, height: 82),
              ),
            ),
          ),
      ],
    );
  }

  Widget _dot() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Container(
          width: 3,
          height: 3,
          decoration: const BoxDecoration(
              color: AppColors.textMuted, shape: BoxShape.circle),
        ),
      );

  String _fmtVotes(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M votes';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K votes';
    return '$n votes';
  }
}

// ═════════════════════════════════════════════════════════════
// Hero placeholder when no token / empty
// ═════════════════════════════════════════════════════════════

class _HeroPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.darkSecondary, AppColors.darkPrimary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const Text(
            'AfterCredits',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Your Cinematic Universe',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════
// Section header
// ═════════════════════════════════════════════════════════════

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;

  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: iconColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: () {},
            child: Text(
              'Lihat Semua',
              style: TextStyle(
                color: iconColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════
// Movie card widget with adult blur support
// ═════════════════════════════════════════════════════════════

class _MovieCardWidget extends StatefulWidget {
  final MovieModel movie;
  final Color accentColor;
  final bool isRevealed;
  final VoidCallback onTapReveal;

  const _MovieCardWidget({
    required this.movie,
    required this.accentColor,
    required this.isRevealed,
    required this.onTapReveal,
  });

  @override
  State<_MovieCardWidget> createState() => _MovieCardWidgetState();
}

class _MovieCardWidgetState extends State<_MovieCardWidget> {
  bool _hovered = false;

  bool get _showBlur => widget.movie.adult && !widget.isRevealed && !_hovered;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.movie.adult ? widget.onTapReveal : () {},
      child: MouseRegion(
        onEnter: (_) {
          if (widget.movie.adult) setState(() => _hovered = true);
        },
        onExit: (_) {
          if (widget.movie.adult) setState(() => _hovered = false);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPoster(),
            const SizedBox(height: 5),
            _buildInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildPoster() {
    return AspectRatio(
      aspectRatio: 2 / 3,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Poster image
            widget.movie.posterUrl != null
                ? _NetImg(
                    url: widget.movie.posterUrl!,
                    fit: BoxFit.cover,
                  )
                : Container(
                    color: AppColors.darkTertiary,
                    child: const Center(
                      child: Icon(Icons.movie_outlined,
                          color: AppColors.textMuted, size: 24),
                    ),
                  ),

            // Adult blur overlay
            if (widget.movie.adult)
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _showBlur
                    ? _buildBlurOverlay()
                    : const SizedBox.shrink(),
              ),

            // Rating badge (hidden when blurred)
            if (!_showBlur)
              Positioned(
                top: 5,
                left: 5,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(185),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star_rounded,
                          color: widget.accentColor, size: 9),
                      const SizedBox(width: 2),
                      Text(
                        widget.movie.ratingFormatted,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Positioned(
                top: 5,
                left: 5,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(185),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(Icons.star_rounded,
                      color: widget.accentColor, size: 9),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlurOverlay() {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
      child: Container(
        color: Colors.black.withAlpha(100),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.visibility_off_rounded,
                  color: Colors.white.withAlpha(180), size: 20),
              const SizedBox(height: 4),
              Text(
                'Dewasa\n${_isDesktop ? 'Hover' : 'Tap'} untuk lihat',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withAlpha(180),
                  fontSize: 9,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (widget.movie.adult)
              Container(
                margin: const EdgeInsets.only(right: 4),
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.accentRed.withAlpha(40),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '18+',
                  style: TextStyle(
                    color: AppColors.accentRed,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            Expanded(
              child: Text(
                widget.movie.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        Text(
          widget.movie.year,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
        ),
      ],
    );
  }

  bool get _isDesktop {
    final platform = Theme.of(context).platform;
    return platform == TargetPlatform.macOS ||
        platform == TargetPlatform.windows ||
        platform == TargetPlatform.linux;
  }
}

// ═════════════════════════════════════════════════════════════
// Hero action buttons
// ═════════════════════════════════════════════════════════════

class _HeroBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isPrimary;
  final VoidCallback onTap;

  const _HeroBtn({
    required this.label,
    required this.icon,
    required this.isPrimary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isPrimary
              ? AppColors.accentRed
              : Colors.white.withAlpha(22),
          borderRadius: BorderRadius.circular(9),
          border: isPrimary
              ? null
              : Border.all(color: Colors.white.withAlpha(45)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 14),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════
// Network image helper
// ═════════════════════════════════════════════════════════════

class _NetImg extends StatelessWidget {
  final String url;
  final BoxFit fit;
  final double? width;
  final double? height;

  const _NetImg({
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      fit: fit,
      width: width,
      height: height,
      loadingBuilder: (_, child, prog) {
        if (prog == null) return child;
        return Container(
          width: width,
          height: height,
          color: AppColors.darkTertiary,
          child: Center(
            child: SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: AppColors.textMuted,
                value: prog.expectedTotalBytes != null
                    ? prog.cumulativeBytesLoaded / prog.expectedTotalBytes!
                    : null,
              ),
            ),
          ),
        );
      },
      errorBuilder: (_, __, ___) => Container(
        width: width,
        height: height,
        color: AppColors.darkTertiary,
        child: const Icon(Icons.broken_image_outlined,
            color: AppColors.textMuted, size: 20),
      ),
    );
  }
}
