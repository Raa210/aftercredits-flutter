import 'dart:math' show pi;
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aftercredits/core/theme/app_theme.dart';
import 'package:aftercredits/core/services/auth_service.dart';
import 'package:aftercredits/core/services/user_profile_service.dart';
import 'package:aftercredits/core/services/follow_service.dart';
import 'package:aftercredits/core/services/community_service.dart';
import 'package:aftercredits/core/services/movie_user_data_service.dart';
import 'package:aftercredits/core/services/tmdb_service.dart';
import 'package:aftercredits/models/user_profile_model.dart';
import 'package:aftercredits/models/movie_model.dart';
import 'package:aftercredits/models/movie_review_model.dart';
import 'package:aftercredits/features/auth/login_screen.dart';
import 'community/community_colors.dart';
import 'community/thread_detail_screen.dart';
import 'package:aftercredits/features/movie_detail/movie_detail_screen.dart';
import 'package:aftercredits/models/community_review_model.dart';
import 'package:aftercredits/features/review_detail/review_detail_screen.dart';
import 'settings_screen.dart';

// ─── Reverse map: genre ID → nama ────────────────────────
const Map<int, String> _kGenreNames = {
  28: 'Aksi',
  18: 'Drama',
  878: 'Sci-Fi',
  35: 'Komedi',
  53: 'Thriller',
  27: 'Horor',
  10749: 'Romansa',
  16: 'Animasi',
  99: 'Dokumenter',
  80: 'Kriminal',
  12: 'Petualangan',
  14: 'Fantasi',
  9648: 'Misteri',
  36: 'Sejarah',
};

// Warna untuk setiap genre
const List<Color> _kGenreColors = [
  AppColors.accentRed,
  Color(0xFF0EA5E9),
  Color(0xFF7C3AED),
  Color(0xFFF59E0B),
  Color(0xFF10B981),
  Color(0xFFEC4899),
  Color(0xFF6366F1),
  Color(0xFF14B8A6),
];

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  UserProfileModel? _profile;
  bool _loadingProfile = true;
  int _followersCount = 0;
  int _followingCount = 0;
  List<Map<String, dynamic>> _userThreads = [];
  final ScrollController _scrollController = ScrollController();
  final MovieUserDataService _userData = MovieUserDataService();

  // Stats
  int _watchlistCount = 0;
  int _watchedCount = 0;
  int _reviewsCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
    _fetchStats();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchProfile() async {
    final user = AuthService().currentUser;
    if (user == null) {
      if (mounted) setState(() => _loadingProfile = false);
      return;
    }
    final results = await Future.wait([
      UserProfileService().getProfile(user.id),
      FollowService().getFollowCounts(user.id),
      CommunityService().getThreadsByUser(user.id),
    ]);

    if (mounted) {
      setState(() {
        _profile = results[0] as UserProfileModel?;
        final counts = results[1] as ({int followers, int following});
        _followersCount = counts.followers;
        _followingCount = counts.following;
        _userThreads = results[2] as List<Map<String, dynamic>>;
        _loadingProfile = false;
      });
    }
  }

  Future<void> _fetchStats() async {
    final watchlist = await _userData.getWatchlistCount();
    final watched = await _userData.getWatchedCount();
    final reviewsMap = await _userData.getAllReviews();
    if (mounted) {
      setState(() {
        _watchlistCount = watchlist;
        _watchedCount = watched;
        _reviewsCount = reviewsMap.length;
      });
    }
  }

  // Refresh stats saat kembali dari detail page
  Future<void> _refreshStats() async {
    await _fetchStats();
  }

  // Helper: display name
  String _displayName(User user) {
    if (_profile != null && _profile!.username.isNotEmpty) {
      return '@${_profile!.username}';
    }
    final meta = user.userMetadata;
    return meta?['full_name'] as String? ??
        meta?['name'] as String? ??
        user.email?.split('@').first ??
        'User';
  }

  // Helper: avatar URL
  String? _avatarUrl(User user) {
    if (_profile?.avatarUrl != null && _profile!.avatarUrl!.isNotEmpty) {
      return _profile!.avatarUrl;
    }
    final meta = user.userMetadata;
    return meta?['avatar_url'] as String? ?? meta?['picture'] as String?;
  }

  // Format tanggal bergabung
  String _joinedLabel(DateTime dt) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
    ];
    return 'Bergabung ${months[dt.month - 1]} ${dt.year}';
  }

  // Buka halaman Pengaturan
  void _openSettings(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
    if (mounted) {
      _fetchProfile();
      _fetchStats();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    final isGuest = user == null;

    return Scaffold(
      backgroundColor: AppColors.darkPrimary,
      body: _loadingProfile && !isGuest
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.accentRed))
          : RefreshIndicator(
              color: AppColors.accentRed,
              backgroundColor: AppColors.darkSecondary,
              onRefresh: () async {
                await _fetchProfile();
                await _fetchStats();
              },
              child: CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics()),
                slivers: [
                  // ── Header ──────────────────────────────────
                  SliverToBoxAdapter(
                    child: isGuest
                        ? _buildGuestHeader(context)
                        : _buildUserHeader(
                            _displayName(user),
                            user.email,
                            _avatarUrl(user),
                          ),
                  ),

                  // ── Stats (logged-in only) ───────────────────
                  if (!isGuest) SliverToBoxAdapter(child: _buildStats()),

                  // ── Tab section ─────────────────────────────
                  if (!isGuest)
                    SliverToBoxAdapter(child: _buildTabSection(context)),

                  // Bottom padding
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 32),
                  ),
                ],
              ),
            ),
    );
  }

  // ── Guest header ───────────────────────────────────────

  Widget _buildGuestHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 24,
        left: 20,
        right: 20,
        bottom: 32,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.darkSecondary, AppColors.darkPrimary],
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.darkTertiary,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border, width: 2),
            ),
            child: const Icon(
              Icons.person_outline_rounded,
              color: AppColors.textMuted,
              size: 40,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Tamu',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Masuk untuk menyimpan progress,\nmenulis review, dan join diskusi',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const AuthScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentRed,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Masuk / Daftar',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Logged-in header ────────────────────────────────────

  Widget _buildUserHeader(
      String? displayName, String? email, String? photoUrl) {
    final joinedLabel =
        _profile != null ? _joinedLabel(_profile!.createdAt) : null;
    final bioText = _profile?.bio;

    return Stack(
      children: [
        // Background gradient
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [Color(0xFF1A0A0A), AppColors.darkPrimary],
              ),
            ),
          ),
        ),
        // Red glow
        Positioned(
          top: -40,
          right: -40,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  AppColors.accentRed.withValues(alpha: 0.2),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        // Content
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.accentRed, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentRed.withValues(alpha: 0.3),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 38,
                  backgroundColor: AppColors.darkTertiary,
                  backgroundImage:
                      photoUrl != null ? NetworkImage(photoUrl) : null,
                  child: photoUrl == null
                      ? Text(
                          (displayName ?? 'U')[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName ?? 'User',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (email != null)
                      Text(
                        email,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 14,
                      runSpacing: 4,
                      children: [
                        _buildInlineStat(_watchedCount, 'Ditonton'),
                        _buildInlineStat(_followersCount, 'Pengikut'),
                        _buildInlineStat(_followingCount, 'Mengikuti'),
                      ],
                    ),
                    if (bioText != null && bioText.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        bioText,
                        style: TextStyle(
                          color: AppColors.textPrimary.withValues(alpha: 0.85),
                          fontSize: 13,
                          height: 1.3,
                        ),
                      ),
                    ],
                    if (joinedLabel != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.accentRed.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: AppColors.accentRed.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          joinedLabel,
                          style: const TextStyle(
                            color: AppColors.accentRed,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Settings icon
              IconButton(
                icon: const Icon(Icons.settings_outlined,
                    color: AppColors.textSecondary),
                tooltip: 'Pengaturan',
                onPressed: () => _openSettings(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInlineStat(int count, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$count',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildStats() {
    return const SizedBox.shrink();
  }

  // ── Tab section ──────────────────────────────────────────

  Widget _buildTabSection(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          const SizedBox(height: 16),
          TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: AppColors.textPrimary,
            unselectedLabelColor: AppColors.textMuted,
            indicatorColor: AppColors.accentRed,
            indicatorSize: TabBarIndicatorSize.label,
            labelStyle: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
            dividerColor: AppColors.border,
            tabs: [
              Tab(text: 'Diskusi (${_userThreads.length})'),
              Tab(text: 'Watchlist ($_watchlistCount)'),
              Tab(text: 'Taste Profile'),
              Tab(text: 'Reviews ($_reviewsCount)'),
            ],
          ),
          SizedBox(
            height: 380,
            child: TabBarView(
              children: [
                _buildDiskusiTab(),
                _WatchlistTab(
                  userData: _userData,
                  onMovieTap: (movie) => _openDetail(context, movie),
                ),
                _buildTasteProfileTab(),
                _ReviewsTab(
                  userData: _userData,
                  profile: _profile,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiskusiTab() {
    if (_userThreads.isEmpty) {
      return _buildEmptyTab(
        icon: Icons.chat_bubble_outline_rounded,
        message: 'Belum ada diskusi',
        sub: 'Diskusi yang kamu buat akan muncul di sini',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      itemCount: _userThreads.length,
      itemBuilder: (context, index) => _buildThreadCard(_userThreads[index]),
    );
  }

  Widget _buildThreadCard(Map<String, dynamic> thread) {
    final tagColor = Color(thread['tagColor'] as int? ?? 0xFFE50914);
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ThreadDetailScreen(thread: thread),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: CommunityColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: CommunityColors.divider.withValues(alpha: 0.5),
            width: 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: tagColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                thread['tag'] as String? ?? '',
                style: TextStyle(
                  color: tagColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              thread['title'] as String? ?? '',
              style: const TextStyle(
                color: CommunityColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.arrow_upward_rounded,
                    size: 12, color: CommunityColors.textMuted),
                const SizedBox(width: 4),
                Text(
                  '${thread['likes']}',
                  style: const TextStyle(
                      color: CommunityColors.textMuted, fontSize: 11),
                ),
                const SizedBox(width: 12),
                Icon(Icons.chat_bubble_outline_rounded,
                    size: 12, color: CommunityColors.textMuted),
                const SizedBox(width: 4),
                Text(
                  '${thread['comments']}',
                  style: const TextStyle(
                      color: CommunityColors.textMuted, fontSize: 11),
                ),
                const Spacer(),
                Text(
                  thread['time'] as String? ?? '',
                  style: const TextStyle(
                      color: CommunityColors.textMuted, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyTab({
    required IconData icon,
    required String message,
    required String sub,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.textMuted, size: 36),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            sub,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  void _openDetail(BuildContext context, MovieModel movie) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => MovieDetailScreen(movie: movie)),
    );
    // Refresh stats setelah kembali dari detail
    _refreshStats();
  }

  // ── Taste Profile tab ─────────────────────────────────────

  Widget _buildTasteProfileTab() {
    return _TasteProfileTab(
      profile: _profile,
      userData: _userData,
    );
  }
}

// ═════════════════════════════════════════════════════════════
// Watchlist Tab
// ═════════════════════════════════════════════════════════════

class _WatchlistTab extends StatefulWidget {
  final MovieUserDataService userData;
  final void Function(MovieModel) onMovieTap;

  const _WatchlistTab({required this.userData, required this.onMovieTap});

  @override
  State<_WatchlistTab> createState() => _WatchlistTabState();
}

class _WatchlistTabState extends State<_WatchlistTab>
    with AutomaticKeepAliveClientMixin {
  final TmdbService _tmdb = TmdbService();
  List<MovieModel> _movies = [];
  bool _loading = true;

  @override
  bool get wantKeepAlive => false; // Tidak cache agar refresh tiap kali tab dibuka

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    final ids = await widget.userData.getWatchlistIds();
    final movies = <MovieModel>[];
    for (final id in ids.take(20)) {
      final m = await _tmdb.getMovieDetails(id);
      if (m != null) movies.add(m);
    }
    if (!mounted) return;
    setState(() {
      _movies = movies;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.accentRed));
    }
    if (_movies.isEmpty) {
      return _buildEmpty();
    }
    return _buildList();
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bookmark_border_rounded, color: AppColors.textMuted, size: 36),
          SizedBox(height: 12),
          Text('Watchlist kamu masih kosong',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w600)),
          SizedBox(height: 4),
          Text('Tambahkan film yang ingin ditonton',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildList() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      itemCount: _movies.length,
      separatorBuilder: (_, __) =>
          const Divider(color: AppColors.border, height: 1, thickness: 0.5),
      itemBuilder: (_, i) => _MovieListTile(
        movie: _movies[i],
        onTap: () => widget.onMovieTap(_movies[i]),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════
// History Tab
// ═════════════════════════════════════════════════════════════

class _HistoryTab extends StatefulWidget {
  final MovieUserDataService userData;
  final void Function(MovieModel) onMovieTap;

  const _HistoryTab({required this.userData, required this.onMovieTap});

  @override
  State<_HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<_HistoryTab>
    with AutomaticKeepAliveClientMixin {
  final TmdbService _tmdb = TmdbService();
  List<MovieModel> _movies = [];
  bool _loading = true;

  @override
  bool get wantKeepAlive => false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    final ids = await widget.userData.getWatchedIds();
    final movies = <MovieModel>[];
    for (final id in ids.reversed.take(20)) {
      final m = await _tmdb.getMovieDetails(id);
      if (m != null) movies.add(m);
    }
    if (!mounted) return;
    setState(() {
      _movies = movies;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.accentRed));
    }
    if (_movies.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_rounded, color: AppColors.textMuted, size: 36),
            SizedBox(height: 12),
            Text('Belum ada riwayat tontonan',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w600)),
            SizedBox(height: 4),
            Text('Film yang sudah ditonton akan muncul di sini',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      itemCount: _movies.length,
      separatorBuilder: (_, __) =>
          const Divider(color: AppColors.border, height: 1, thickness: 0.5),
      itemBuilder: (_, i) => _MovieListTile(
        movie: _movies[i],
        onTap: () => widget.onMovieTap(_movies[i]),
        trailing: const Icon(Icons.check_circle_rounded,
            color: Color(0xFF10B981), size: 18),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════
// Reviews Tab
// ═════════════════════════════════════════════════════════════

class _ReviewsTab extends StatefulWidget {
  final MovieUserDataService userData;
  final UserProfileModel? profile;

  const _ReviewsTab({required this.userData, this.profile});

  @override
  State<_ReviewsTab> createState() => _ReviewsTabState();
}

class _ReviewsTabState extends State<_ReviewsTab>
    with AutomaticKeepAliveClientMixin {
  final TmdbService _tmdb = TmdbService();
  List<Map<String, dynamic>> _items = []; // {movie, review}
  bool _loading = true;

  @override
  bool get wantKeepAlive => false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    final reviews = await widget.userData.getAllReviews();
    final items = <Map<String, dynamic>>[];
    for (final entry in reviews.entries) {
      final movie = await _tmdb.getMovieDetails(entry.key);
      if (movie != null) {
        items.add({'movie': movie, 'review': entry.value});
      }
    }
    // Sort by createdAt descending
    items.sort((a, b) {
      final rA = (a['review'] as MovieReview).createdAt;
      final rB = (b['review'] as MovieReview).createdAt;
      return rB.compareTo(rA);
    });
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.accentRed));
    }
    if (_items.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.rate_review_outlined, color: AppColors.textMuted, size: 36),
            SizedBox(height: 12),
            Text('Belum ada review',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w600)),
            SizedBox(height: 4),
            Text('Bagikan pendapatmu tentang film yang ditonton',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      itemCount: _items.length,
      separatorBuilder: (_, __) =>
          const Divider(color: AppColors.border, height: 1, thickness: 0.5),
      itemBuilder: (_, i) {
        final movie = _items[i]['movie'] as MovieModel;
        final review = _items[i]['review'] as MovieReview;
        return _ReviewListTile(
          movie: movie,
          review: review,
          onTap: () {
            final currentUser = AuthService().currentUser;
            final username = widget.profile?.username ?? currentUser?.email?.split('@').first ?? 'Kamu';
            final avatarUrl = widget.profile?.avatarUrl;
            
            final now = DateTime.now();
            final diff = now.difference(review.createdAt);
            String timeLabel;
            if (diff.inMinutes < 60) {
              timeLabel = '${diff.inMinutes <= 0 ? 1 : diff.inMinutes} menit lalu';
            } else if (diff.inHours < 24) {
              timeLabel = '${diff.inHours} jam lalu';
            } else if (diff.inDays < 7) {
              timeLabel = '${diff.inDays} hari lalu';
            } else {
              timeLabel = '${review.createdAt.day}/${review.createdAt.month}/${review.createdAt.year}';
            }

            final communityReview = CommunityReviewModel(
              id: 'user_rev_${review.movieId}',
              movieId: review.movieId,
              movieTitle: movie.title,
              posterUrl: movie.posterUrl,
              authorName: username,
              authorAvatar: avatarUrl,
              rating: review.rating,
              text: review.text,
              likesCount: 0,
              timeLabel: timeLabel,
              isUserReview: true,
            );

            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ReviewDetailScreen(review: communityReview),
              ),
            ).then((_) {
              _load();
            });
          },
          onEdit: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => MovieDetailScreen(movie: movie),
              ),
            ).then((_) => _load());
          },
          onDelete: () {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: AppColors.darkSecondary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: const Text('Hapus Review', style: TextStyle(color: AppColors.textPrimary)),
                content: const Text('Apakah kamu yakin ingin menghapus review untuk film ini?',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Batal', style: TextStyle(color: AppColors.textMuted)),
                  ),
                  TextButton(
                    onPressed: () async {
                      Navigator.of(ctx).pop();
                      await widget.userData.deleteReview(movie.id);
                      if (mounted) {
                        _load();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Review berhasil dihapus', style: TextStyle(color: Colors.white)),
                            backgroundColor: AppColors.darkTertiary,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      }
                    },
                    child: const Text('Hapus', style: TextStyle(color: AppColors.accentRed, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ═════════════════════════════════════════════════════════════
// Taste Profile Tab
// ═════════════════════════════════════════════════════════════

class _TasteProfileTab extends StatefulWidget {
  final UserProfileModel? profile;
  final MovieUserDataService userData;

  const _TasteProfileTab({required this.profile, required this.userData});

  @override
  State<_TasteProfileTab> createState() => _TasteProfileTabState();
}

class _TasteProfileTabState extends State<_TasteProfileTab> {
  Map<int, int> _watchedGenreCounts = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final counts = await widget.userData.getWatchedGenreCounts();
    if (mounted) {
      setState(() {
        _watchedGenreCounts = counts;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.accentRed));
    }

    // Gabungkan onboarding genres + watched genres
    final onboardingIds = widget.profile?.favoriteGenreIds ?? [];
    final combinedMap = <int, double>{};

    // Tambah onboarding genres sebagai base weight (hanya jika belum ada watched data)
    if (_watchedGenreCounts.isEmpty) {
      for (final id in onboardingIds) {
        combinedMap[id] = (combinedMap[id] ?? 0) + 1.0;
      }
    } else {
      // Watched history menjadi sumber utama
      for (final entry in _watchedGenreCounts.entries) {
        combinedMap[entry.key] = (combinedMap[entry.key] ?? 0) + entry.value.toDouble();
      }
      // Tambah onboarding sebagai bobot kecil (0.3 per genre)
      for (final id in onboardingIds) {
        if (!_watchedGenreCounts.containsKey(id)) {
          combinedMap[id] = (combinedMap[id] ?? 0) + 0.3;
        }
      }
    }

    if (combinedMap.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.movie_filter_outlined, color: AppColors.textMuted, size: 36),
            const SizedBox(height: 12),
            const Text('Belum ada data selera',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              _watchedGenreCounts.isEmpty
                  ? 'Tonton lebih banyak film untuk memperbarui taste profile'
                  : 'Pilih genre favorit di pengaturan profil',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final total = combinedMap.values.fold(0.0, (a, b) => a + b);
    final sortedEntries = combinedMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topEntries = sortedEntries.take(6).toList();

    final genres = topEntries.asMap().entries.map((e) {
      final idx = e.key;
      final genreId = e.value.key;
      final weight = e.value.value;
      final name = _kGenreNames[genreId] ?? 'Genre $genreId';
      final pct = total > 0 ? weight / total : 0.0;
      final color = _kGenreColors[idx % _kGenreColors.length];
      return {'label': name, 'pct': pct, 'color': color};
    }).toList();

    final subtitle = _watchedGenreCounts.isNotEmpty
        ? 'Berdasarkan ${_watchedGenreCounts.values.fold(0, (a, b) => a + b)} film yang ditonton.'
        : 'Berdasarkan preferensi awal kamu.';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Movie Taste Profile',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: CustomPaint(painter: _DonutChartPainter(genres)),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: genres.map((g) {
                    final color = g['color'] as Color;
                    final pct = ((g['pct'] as double) * 100).round();
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$pct%  ${g['label']}',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════
// Shared list tile widgets
// ═════════════════════════════════════════════════════════════

class _MovieListTile extends StatelessWidget {
  final MovieModel movie;
  final VoidCallback onTap;
  final Widget? trailing;

  const _MovieListTile({
    required this.movie,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
      onTap: onTap,
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: movie.posterUrl != null
            ? Image.network(
                movie.posterUrl!,
                width: 40,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _posterPlaceholder(),
              )
            : _posterPlaceholder(),
      ),
      title: Text(
        movie.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        '${movie.year}  •  ★ ${movie.ratingFormatted}',
        style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
      ),
      trailing: trailing ??
          const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
    );
  }

  Widget _posterPlaceholder() {
    return Container(
      width: 40,
      height: 60,
      color: AppColors.darkTertiary,
      child: const Icon(Icons.movie_outlined, color: AppColors.textMuted, size: 18),
    );
  }
}

class _ReviewListTile extends StatelessWidget {
  final MovieModel movie;
  final MovieReview review;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _ReviewListTile({
    required this.movie,
    required this.review,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: movie.posterUrl != null
                  ? Image.network(
                      movie.posterUrl!,
                      width: 40,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 40, height: 60,
                        color: AppColors.darkTertiary,
                        child: const Icon(Icons.movie_outlined, size: 18, color: AppColors.textMuted),
                      ),
                    )
                  : Container(
                      width: 40, height: 60,
                      color: AppColors.darkTertiary,
                      child: const Icon(Icons.movie_outlined, size: 18, color: AppColors.textMuted),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movie.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: List.generate(5, (i) {
                      final isFull = review.rating >= i + 1;
                      final isHalf = !isFull && review.rating >= i + 0.5;
                      return Icon(
                        isFull ? Icons.star_rounded : isHalf ? Icons.star_half_rounded : Icons.star_border_rounded,
                        color: (isFull || isHalf) ? AppColors.star : AppColors.border,
                        size: 13,
                      );
                    }),
                  ),
                  if (review.text.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      review.text,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (onEdit != null || onDelete != null)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, color: AppColors.textMuted, size: 18),
                color: AppColors.darkSecondary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onSelected: (val) {
                  if (val == 'edit') onEdit?.call();
                  if (val == 'delete') onDelete?.call();
                },
                itemBuilder: (_) => [
                  if (onEdit != null)
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, color: AppColors.textPrimary, size: 18),
                          SizedBox(width: 8),
                          Text('Edit Review', style: TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                        ],
                      ),
                    ),
                  if (onDelete != null)
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline_rounded, color: AppColors.accentRed, size: 18),
                          SizedBox(width: 8),
                          Text('Hapus', style: TextStyle(color: AppColors.accentRed, fontSize: 13)),
                        ],
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════
// Stat item widget
// ═════════════════════════════════════════════════════════════

class _StatItem extends StatelessWidget {
  final String value;
  final String label;

  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 32, color: AppColors.border);
  }
}

// ═════════════════════════════════════════════════════════════
// Donut chart painter
// ═════════════════════════════════════════════════════════════

class _DonutChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;

  _DonutChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final strokeWidth = radius * 0.38;
    final innerRadius = radius - strokeWidth;
    var startAngle = -pi / 2;

    for (final item in data) {
      final sweep = (item['pct'] as double) * 2 * pi;
      final paint = Paint()
        ..color = item['color'] as Color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(
        Rect.fromCircle(
            center: center, radius: innerRadius + strokeWidth / 2),
        startAngle,
        sweep,
        false,
        paint,
      );
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
