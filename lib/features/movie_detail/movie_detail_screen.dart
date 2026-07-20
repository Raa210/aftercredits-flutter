import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:animate_do/animate_do.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:aftercredits/core/theme/app_theme.dart';
import 'package:aftercredits/core/services/tmdb_service.dart';
import 'package:aftercredits/core/services/movie_user_data_service.dart';
import 'package:aftercredits/core/services/auth_service.dart';
import 'package:aftercredits/models/movie_model.dart';
import 'package:aftercredits/models/cast_model.dart';
import 'package:aftercredits/models/movie_review_model.dart';
import 'package:aftercredits/core/services/review_community_service.dart';
import 'package:aftercredits/models/community_review_model.dart';
import 'package:aftercredits/features/review_detail/review_detail_screen.dart';
import 'package:aftercredits/features/home/tabs/community/user_profile_screen.dart';

// ─── Genre map (ID → Nama) ───────────────────────────────────
const Map<int, String> _kGenreNames = {
  28: 'Aksi', 12: 'Petualangan', 16: 'Animasi', 35: 'Komedi',
  80: 'Kriminal', 99: 'Dokumenter', 18: 'Drama', 10751: 'Keluarga',
  14: 'Fantasi', 36: 'Sejarah', 27: 'Horor', 10402: 'Musik',
  9648: 'Misteri', 10749: 'Romansa', 878: 'Sci-Fi', 10770: 'TV Movie',
  53: 'Thriller', 10752: 'Perang', 37: 'Barat',
};

// ─── Language map ─────────────────────────────────────────────
const Map<String, String> _kLanguageNames = {
  'en': 'English', 'id': 'Indonesia', 'ja': 'Jepang', 'ko': 'Korea',
  'fr': 'Prancis', 'de': 'Jerman', 'es': 'Spanyol', 'it': 'Italia',
  'zh': 'Mandarin', 'hi': 'Hindi', 'pt': 'Portugis', 'ru': 'Rusia',
  'ar': 'Arab', 'th': 'Thai', 'tr': 'Turki',
};

// ═════════════════════════════════════════════════════════════
// Movie Detail Screen
// ═════════════════════════════════════════════════════════════

class MovieDetailScreen extends StatefulWidget {
  final MovieModel movie;

  const MovieDetailScreen({super.key, required this.movie});

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  final TmdbService _tmdb = TmdbService();
  final MovieUserDataService _userData = MovieUserDataService();

  // Detail data
  MovieModel? _detail;
  List<CastModel> _cast = [];
  String? _trailerKey;
  bool _loadingDetail = true;

  // User state
  bool _isWatched = false;
  bool _isInWatchlist = false;
  MovieReview? _existingReview;
  List<CommunityReviewModel> _communityReviews = [];

  // Review form
  double _reviewRating = 0;
  final TextEditingController _reviewController = TextEditingController();
  bool _submittingReview = false;
  bool _showReviewForm = false;
  bool _overviewExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadDetail();
    _loadUserState();
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  // ─── Data loading ──────────────────────────────────────────

  Future<void> _loadDetail() async {
    final raw = await _tmdb.getMovieDetailsRaw(widget.movie.id);
    if (!mounted) return;

    if (raw != null) {
      final detail = MovieModel.fromJson(raw);
      final cast = _tmdb.parseCast(raw);
      final trailerKey = _tmdb.parseTrailerKey(raw);
      setState(() {
        _detail = detail;
        _cast = cast;
        _trailerKey = trailerKey;
        _loadingDetail = false;
      });
    } else {
      setState(() {
        _detail = widget.movie;
        _loadingDetail = false;
      });
    }
  }

  Future<void> _loadUserState() async {
    final watched = await _userData.isWatched(widget.movie.id);
    final watchlist = await _userData.isInWatchlist(widget.movie.id);
    final review = await _userData.getReview(widget.movie.id);
    final commReviews = await ReviewCommunityService().getReviewsForMovie(widget.movie.id);
    if (!mounted) return;
    setState(() {
      _isWatched = watched;
      _isInWatchlist = watchlist;
      _existingReview = review;
      _communityReviews = commReviews;
      if (review != null) {
        _reviewRating = review.rating;
        _reviewController.text = review.text;
      }
    });
  }

  // ─── User actions ──────────────────────────────────────────

  Future<void> _toggleWatched() async {
    if (!_isLoggedIn) { _showLoginSnack(); return; }
    HapticFeedback.lightImpact();
    final nowWatched = await _userData.toggleWatched(
      widget.movie.id,
      movieTitle: widget.movie.title,
      posterUrl: widget.movie.posterPath,
    );

    // Simpan genre dari film ini untuk Movie Taste
    final movie = _detail ?? widget.movie;
    if (nowWatched) {
      final genreIds = movie.genres.isNotEmpty
          ? movie.genres.map((g) => g['id'] as int? ?? 0).where((id) => id != 0).toList()
          : movie.genreIds;
      if (genreIds.isNotEmpty) {
        await _userData.saveMovieGenres(movie.id, genreIds);
      }
    }

    if (!mounted) return;
    setState(() => _isWatched = nowWatched);
    _showSnack(nowWatched ? 'Ditandai sebagai ditonton ✓' : 'Dihapus dari riwayat tontonan');
  }

  Future<void> _toggleWatchlist() async {
    if (!_isLoggedIn) { _showLoginSnack(); return; }
    HapticFeedback.lightImpact();
    final nowInWatchlist = await _userData.toggleWatchlist(
      widget.movie.id,
      movieTitle: widget.movie.title,
      posterUrl: widget.movie.posterPath,
    );
    if (!mounted) return;
    setState(() => _isInWatchlist = nowInWatchlist);
    _showSnack(nowInWatchlist ? 'Ditambahkan ke Watchlist ✓' : 'Dihapus dari Watchlist');
  }

  Future<void> _submitReview() async {
    if (!_isLoggedIn) { _showLoginSnack(); return; }
    if (_reviewRating == 0) {
      _showSnack('Pilih rating terlebih dahulu');
      return;
    }

    setState(() => _submittingReview = true);
    await _userData.saveReview(
      movieId: widget.movie.id,
      rating: _reviewRating,
      text: _reviewController.text,
      movieTitle: widget.movie.title,
      posterUrl: widget.movie.posterUrl,
    );

    if (!mounted) return;
    final review = await _userData.getReview(widget.movie.id);
    setState(() {
      _existingReview = review;
      _submittingReview = false;
      _showReviewForm = false;
    });
    _showSnack('Review berhasil disimpan ✓');
  }

  Future<void> _deleteReview() async {
    await _userData.deleteReview(widget.movie.id);
    if (!mounted) return;
    setState(() {
      _existingReview = null;
      _reviewRating = 0;
      _reviewController.clear();
    });
    _showSnack('Review dihapus');
  }

  Future<void> _openTrailer() async {
    if (_trailerKey == null) return;
    final uri = Uri.parse('https://www.youtube.com/watch?v=$_trailerKey');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  bool get _isLoggedIn => AuthService().currentUser != null;

  void _showLoginSnack() {
    _showSnack('Masuk terlebih dahulu untuk menggunakan fitur ini');
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white, fontSize: 13)),
        backgroundColor: AppColors.darkTertiary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ─── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final movie = _detail ?? widget.movie;
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.darkPrimary,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Header / SliverAppBar ─────────────────────────
          _buildSliverHeader(movie, topPad),

          // ── Body content ──────────────────────────────────
          if (_loadingDetail)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: AppColors.accentRed)),
            )
          else ...[
            // Action buttons
            SliverToBoxAdapter(child: _buildActionButtons()),

            // Genre chips
            SliverToBoxAdapter(child: _buildGenreChips(movie)),

            // Sinopsis
            SliverToBoxAdapter(child: _buildOverview(movie)),

            // Info tambahan
            SliverToBoxAdapter(child: _buildInfo(movie)),

            // Divider
            const SliverToBoxAdapter(child: _Divider()),

            // Trailer
            SliverToBoxAdapter(child: _buildTrailerSection()),

            // Divider
            const SliverToBoxAdapter(child: _Divider()),

            // Cast
            SliverToBoxAdapter(child: _buildCastSection()),

            // Divider
            const SliverToBoxAdapter(child: _Divider()),

            // Review
            SliverToBoxAdapter(child: _buildReviewSection()),

            // Bottom padding
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ],
      ),
    );
  }

  // ─── Sliver Header ─────────────────────────────────────────

  Widget _buildSliverHeader(MovieModel movie, double topPad) {
    return SliverAppBar(
      expandedHeight: 320,
      pinned: true,
      backgroundColor: AppColors.darkPrimary,
      leading: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 18),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Backdrop
            movie.backdropUrl != null
                ? Image.network(
                    movie.backdropUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: AppColors.darkSecondary),
                  )
                : Container(color: AppColors.darkSecondary),

            // Gradient overlay
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x22000000),
                    Color(0x88000000),
                    AppColors.darkPrimary,
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
            ),

            // Poster + info overlay (bottom)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Poster
                  if (movie.posterUrl != null)
                    Container(
                      width: 90,
                      height: 135,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.6),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          movie.posterLargeUrl ?? movie.posterUrl!,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  const SizedBox(width: 14),

                  // Title + meta
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          movie.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            height: 1.2,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if ((movie.tagline ?? '').isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            '"${movie.tagline}"',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.65),
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 8),
                        // Meta row
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            if (movie.year != '-')
                              _MetaBadge(text: movie.year),
                            if (movie.runtimeFormatted != null)
                              _MetaBadge(text: movie.runtimeFormatted!),
                            if (movie.voteAverage > 0)
                              _MetaBadge(
                                text: '★ ${movie.ratingFormatted}',
                                color: AppColors.star,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Action Buttons ────────────────────────────────────────

  Widget _buildActionButtons() {
    return FadeInUp(
      duration: const Duration(milliseconds: 350),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
        child: Row(
          children: [
            Expanded(
              child: _ActionButton(
                icon: _isWatched
                    ? Icons.check_circle_rounded
                    : Icons.check_circle_outline_rounded,
                label: _isWatched ? 'Ditonton' : 'Tandai Ditonton',
                isActive: _isWatched,
                activeColor: const Color(0xFF10B981),
                onTap: _toggleWatched,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ActionButton(
                icon: _isInWatchlist
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
                label: _isInWatchlist ? 'Di Watchlist' : 'Tambah Watchlist',
                isActive: _isInWatchlist,
                activeColor: AppColors.accentRed,
                onTap: _toggleWatchlist,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Genre Chips ───────────────────────────────────────────

  Widget _buildGenreChips(MovieModel movie) {
    final genres = _getGenreNames(movie);
    if (genres.isEmpty) return const SizedBox(height: 20);

    return FadeInUp(
      duration: const Duration(milliseconds: 400),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 16, 0, 0),
        child: SizedBox(
          height: 34,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: genres.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.accentRed.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.accentRed.withOpacity(0.35)),
              ),
              child: Text(
                genres[i],
                style: const TextStyle(
                  color: AppColors.accentRed,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<String> _getGenreNames(MovieModel movie) {
    if (movie.genres.isNotEmpty) {
      return movie.genres
          .map((g) => g['name'] as String? ?? '')
          .where((n) => n.isNotEmpty)
          .toList();
    }
    // fallback ke genreIds
    return movie.genreIds
        .map((id) => _kGenreNames[id] ?? '')
        .where((n) => n.isNotEmpty)
        .toList();
  }

  // ─── Overview ──────────────────────────────────────────────

  Widget _buildOverview(MovieModel movie) {
    final overview = movie.overview ?? '';
    if (overview.isEmpty) return const SizedBox.shrink();

    final isLong = overview.length > 200;

    return FadeInUp(
      duration: const Duration(milliseconds: 450),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle(title: 'Sinopsis'),
            const SizedBox(height: 10),
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: Text(
                overview,
                maxLines: _overviewExpanded ? null : 4,
                overflow: _overviewExpanded ? null : TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
            ),
            if (isLong) ...[
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => setState(() => _overviewExpanded = !_overviewExpanded),
                child: Text(
                  _overviewExpanded ? 'Lihat lebih sedikit' : 'Lihat selengkapnya',
                  style: const TextStyle(
                    color: AppColors.accentRed,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─── Info ──────────────────────────────────────────────────

  Widget _buildInfo(MovieModel movie) {
    final lang = _kLanguageNames[movie.originalLanguage] ?? movie.originalLanguage;
    final releaseDate = _formatDate(movie.releaseDate);

    final items = <Map<String, String?>>[];
    if (lang != null && lang.isNotEmpty) {
      items.add({'label': 'Bahasa', 'value': lang});
    }
    if (releaseDate != null) {
      items.add({'label': 'Rilis', 'value': releaseDate});
    }
    if (movie.status != null && movie.status!.isNotEmpty) {
      items.add({'label': 'Status', 'value': _translateStatus(movie.status!)});
    }

    if (items.isEmpty) return const SizedBox(height: 16);

    return FadeInUp(
      duration: const Duration(milliseconds: 500),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
        child: Wrap(
          spacing: 20,
          runSpacing: 12,
          children: items.map((item) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item['label']!,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                item['value'] ?? '-',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          )).toList(),
        ),
      ),
    );
  }

  String? _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    try {
      final dt = DateTime.parse(dateStr);
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
      ];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return dateStr;
    }
  }

  String _translateStatus(String status) {
    const map = {
      'Released': 'Sudah Rilis',
      'In Production': 'Dalam Produksi',
      'Post Production': 'Pasca Produksi',
      'Planned': 'Direncanakan',
      'Canceled': 'Dibatalkan',
      'Rumored': 'Masih Rumor',
    };
    return map[status] ?? status;
  }

  // ─── Trailer Section ───────────────────────────────────────

  Widget _buildTrailerSection() {
    return FadeInUp(
      duration: const Duration(milliseconds: 500),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle(title: 'Trailer'),
            const SizedBox(height: 14),
            if (_trailerKey != null)
              _TrailerThumbnail(
                trailerKey: _trailerKey!,
                onTap: _openTrailer,
              )
            else
              _EmptyState(
                icon: Icons.play_circle_outline_rounded,
                message: 'Trailer belum tersedia',
                sub: 'Trailer tidak ditemukan untuk film ini',
              ),
          ],
        ),
      ),
    );
  }

  // ─── Cast Section ──────────────────────────────────────────

  Widget _buildCastSection() {
    return FadeInUp(
      duration: const Duration(milliseconds: 550),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 24, 0, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: _SectionTitle(title: 'Pemeran'),
            ),
            const SizedBox(height: 14),
            if (_cast.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _EmptyState(
                  icon: Icons.people_outline_rounded,
                  message: 'Data pemeran tidak tersedia',
                  sub: 'Informasi cast tidak ditemukan',
                ),
              )
            else
              SizedBox(
                height: 160,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: _cast.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, i) => _CastCard(cast: _cast[i]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ─── Review Section ────────────────────────────────────────

  Widget _buildReviewSection() {
    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle(title: 'Review Kamu'),
            const SizedBox(height: 14),

            // Existing review card
            if (_existingReview != null && !_showReviewForm)
              _buildExistingReview(_existingReview!)
            // Review form
            else if (_showReviewForm || _existingReview == null)
              _buildReviewForm(),

            // Toggle form button (jika sudah ada review dan form tidak tampil)
            if (_existingReview != null && !_showReviewForm) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  _OutlineButton(
                    label: 'Edit Review',
                    icon: Icons.edit_outlined,
                    onTap: () => setState(() => _showReviewForm = true),
                  ),
                  const SizedBox(width: 10),
                  _OutlineButton(
                    label: 'Hapus',
                    icon: Icons.delete_outline_rounded,
                    color: AppColors.accentRed,
                    onTap: _deleteReview,
                  ),
                ],
              ),
            ],

            if (_showReviewForm && _existingReview != null) ...[
              const SizedBox(height: 12),
              _OutlineButton(
                label: 'Batal',
                icon: Icons.close_rounded,
                onTap: () {
                  setState(() {
                    _showReviewForm = false;
                    _reviewRating = _existingReview?.rating ?? 0;
                    _reviewController.text = _existingReview?.text ?? '';
                  });
                },
              ),
            ],

            if (_communityReviews.isNotEmpty) ...[
              const SizedBox(height: 32),
              _SectionTitle(title: 'Review dari Komunitas (${_communityReviews.length})'),
              const SizedBox(height: 14),
              ...List.generate(
                _communityReviews.length,
                (i) => _buildCommunityReviewCard(_communityReviews[i]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildExistingReview(MovieReview review) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _StarRatingDisplay(rating: review.rating, size: 18),
              const SizedBox(width: 8),
              Text(
                review.rating.toStringAsFixed(1),
                style: const TextStyle(
                  color: AppColors.star,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                _formatDate(review.createdAt.toIso8601String().split('T').first) ?? '',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          if (review.text.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              review.text,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _openUserProfile(String username, String? avatarUrl, [String? userId]) {
    if (userId == null || userId.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => UserProfileScreen(
          userId: userId,
          username: username,
          avatarUrl: avatarUrl,
        ),
      ),
    );
  }

  Widget _buildCommunityReviewCard(CommunityReviewModel review) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ReviewDetailScreen(review: review),
          ),
        ).then((_) => _loadUserState());
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.darkSecondary,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _openUserProfile(review.authorName, review.authorAvatar, review.authorId),
                    behavior: HitTestBehavior.opaque,
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: AppColors.darkTertiary,
                          backgroundImage: review.authorAvatar != null
                              ? NetworkImage(review.authorAvatar!)
                              : null,
                          child: review.authorAvatar == null
                              ? const Icon(Icons.person, size: 16, color: AppColors.textSecondary)
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            review.authorName,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _StarRatingDisplay(rating: review.rating, size: 14),
                const SizedBox(width: 6),
                Text(
                  review.rating.toStringAsFixed(1),
                  style: const TextStyle(
                    color: AppColors.star,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            if (review.text.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                review.text,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  review.isUserReview ? Icons.person_outline : Icons.favorite_border_rounded,
                  size: 14,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 4),
                Text(
                  review.isUserReview ? 'Review kamu' : '${review.likesCount} suka',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
                const Spacer(),
                Text(
                  review.timeLabel,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Star rating input
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.darkSecondary,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Rating',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 10),
              _StarRatingInput(
                rating: _reviewRating,
                onChanged: (val) => setState(() => _reviewRating = val),
              ),
              if (_reviewRating > 0) ...[
                const SizedBox(height: 6),
                Text(
                  '${_reviewRating.toStringAsFixed(1)} / 5.0  •  ${_ratingLabel(_reviewRating)}',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Text review
        Container(
          decoration: BoxDecoration(
            color: AppColors.darkTertiary,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border, width: 0.5),
          ),
          child: TextField(
            controller: _reviewController,
            maxLines: 4,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            decoration: const InputDecoration(
              hintText: 'Tulis pendapatmu tentang film ini...',
              hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(14),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Submit button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _submittingReview ? null : _submitReview,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentRed,
              disabledBackgroundColor: AppColors.accentRed.withOpacity(0.5),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: _submittingReview
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Simpan Review',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  String _ratingLabel(double r) {
    if (r >= 4.5) return 'Masterpiece';
    if (r >= 4.0) return 'Luar Biasa';
    if (r >= 3.5) return 'Bagus Sekali';
    if (r >= 3.0) return 'Bagus';
    if (r >= 2.5) return 'Lumayan';
    if (r >= 2.0) return 'Biasa Saja';
    if (r >= 1.5) return 'Kurang';
    if (r >= 1.0) return 'Buruk';
    return 'Sangat Buruk';
  }
}

// ═════════════════════════════════════════════════════════════
// Helper widgets
// ═════════════════════════════════════════════════════════════

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.accentRed, AppColors.accentOrange],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _MetaBadge extends StatelessWidget {
  final String text;
  final Color color;
  const _MetaBadge({required this.text, this.color = AppColors.textSecondary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.45),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      height: 0.5,
      color: AppColors.border,
    );
  }
}

// ─── Action Button ────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withOpacity(0.15) : AppColors.darkSecondary,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive ? activeColor.withOpacity(0.6) : AppColors.border,
            width: isActive ? 1 : 0.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                icon,
                key: ValueKey(isActive),
                color: isActive ? activeColor : AppColors.textMuted,
                size: 22,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                color: isActive ? activeColor : AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Trailer Thumbnail ────────────────────────────────────────

class _TrailerThumbnail extends StatelessWidget {
  final String trailerKey;
  final VoidCallback onTap;

  const _TrailerThumbnail({required this.trailerKey, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final thumbUrl = 'https://img.youtube.com/vi/$trailerKey/maxresdefault.jpg';
    final fallbackUrl = 'https://img.youtube.com/vi/$trailerKey/hqdefault.jpg';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Thumbnail
              Image.network(
                thumbUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Image.network(
                  fallbackUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(color: AppColors.darkSecondary),
                ),
              ),

              // Dark overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.4),
                    ],
                  ),
                ),
              ),

              // Play button
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.accentRed,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accentRed.withOpacity(0.5),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              ),

              // Label
              Positioned(
                bottom: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.play_circle_outline_rounded,
                          color: Colors.white, size: 13),
                      SizedBox(width: 4),
                      Text(
                        'Buka di YouTube',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
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
    );
  }
}

// ─── Cast Card ────────────────────────────────────────────────

class _CastCard extends StatelessWidget {
  final CastModel cast;
  const _CastCard({required this.cast});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border, width: 1),
            ),
            child: ClipOval(
              child: cast.profileUrl != null
                  ? Image.network(
                      cast.profileUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _avatarPlaceholder(),
                    )
                  : _avatarPlaceholder(),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            cast.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
          if (cast.character != null && cast.character!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              cast.character!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 10,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _avatarPlaceholder() {
    return Container(
      color: AppColors.darkTertiary,
      child: const Icon(Icons.person_rounded, color: AppColors.textMuted, size: 32),
    );
  }
}

// ─── Star Rating Input ────────────────────────────────────────

class _StarRatingInput extends StatelessWidget {
  final double rating;
  final ValueChanged<double> onChanged;

  const _StarRatingInput({required this.rating, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (details) => _updateRating(context, details.localPosition.dx),
      onPanUpdate: (details) => _updateRating(context, details.localPosition.dx),
      child: SizedBox(
        height: 36,
        child: LayoutBuilder(
          builder: (context, constraints) {
            const starCount = 5;
            final starWidth = constraints.maxWidth / starCount;
            return Row(
              children: List.generate(starCount, (i) {
                final starValue = i + 1.0;
                final halfValue = i + 0.5;
                final isFull = rating >= starValue;
                final isHalf = !isFull && rating >= halfValue;

                return SizedBox(
                  width: starWidth,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 150),
                    child: Icon(
                      isFull
                          ? Icons.star_rounded
                          : isHalf
                              ? Icons.star_half_rounded
                              : Icons.star_border_rounded,
                      key: ValueKey('$i-${isFull ? 'full' : isHalf ? 'half' : 'empty'}'),
                      color: (isFull || isHalf) ? AppColors.star : AppColors.border,
                      size: 32,
                    ),
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }

  void _updateRating(BuildContext context, double localX) {
    const starCount = 5;
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final totalWidth = renderBox.size.width;
    final starWidth = totalWidth / starCount;
    final starIndex = (localX / starWidth).floor().clamp(0, starCount - 1);
    final withinStar = localX - (starIndex * starWidth);
    final newRating = withinStar > starWidth / 2
        ? (starIndex + 1).toDouble()
        : starIndex + 0.5;
    onChanged(newRating.clamp(0.5, 5.0));
  }
}

// ─── Star Rating Display (read-only) ─────────────────────────

class _StarRatingDisplay extends StatelessWidget {
  final double rating;
  final double size;

  const _StarRatingDisplay({required this.rating, this.size = 14});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final starValue = i + 1.0;
        final halfValue = i + 0.5;
        final isFull = rating >= starValue;
        final isHalf = !isFull && rating >= halfValue;
        return Icon(
          isFull ? Icons.star_rounded : isHalf ? Icons.star_half_rounded : Icons.star_border_rounded,
          color: (isFull || isHalf) ? AppColors.star : AppColors.border,
          size: size,
        );
      }),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String sub;

  const _EmptyState({
    required this.icon,
    required this.message,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.darkSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.textMuted, size: 32),
          const SizedBox(height: 10),
          Text(
            message,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            sub,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── Outline Button ───────────────────────────────────────────

class _OutlineButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _OutlineButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.color = AppColors.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.4)),
          color: color.withOpacity(0.08),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 15),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
