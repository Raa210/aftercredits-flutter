import 'dart:math' show pi;
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/user_profile_service.dart';
import '../../../models/user_profile_model.dart';
import '../../auth/login_screen.dart';
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
};

// Warna untuk setiap genre (max 6 ditampilkan)
const List<Color> _kGenreColors = [
  AppColors.accentRed,
  Color(0xFF0EA5E9),
  Color(0xFF7C3AED),
  Color(0xFFF59E0B),
  Color(0xFF10B981),
  Color(0xFFEC4899),
];

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  UserProfileModel? _profile;
  bool _loadingProfile = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchProfile();
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
    final profile = await UserProfileService().getProfile(user.id);
    if (mounted) {
      setState(() {
        _profile = profile;
        _loadingProfile = false;
      });
    }
  }

  // Helper: display name dengan @ prefix dari username Supabase,
  // fallback ke Google metadata jika profil belum ada
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

  // Helper: avatar URL dari Supabase Storage, fallback ke Google picture
  String? _avatarUrl(User user) {
    if (_profile?.avatarUrl != null && _profile!.avatarUrl!.isNotEmpty) {
      return _profile!.avatarUrl;
    }
    final meta = user.userMetadata;
    return meta?['avatar_url'] as String? ?? meta?['picture'] as String?;
  }

  // Format tanggal bergabung dari createdAt → "Juli 2025"
  String _joinedLabel(DateTime dt) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
    ];
    return 'Bergabung ${months[dt.month - 1]} ${dt.year}';
  }

  // Buka halaman Pengaturan
  void _openSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
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
          : CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
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
    // Tanggal bergabung dari profil Supabase
    final joinedLabel =
        _profile != null ? _joinedLabel(_profile!.createdAt) : null;

    return Stack(
      children: [
        // Background gradient
        Container(
          height: 220,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [Color(0xFF1A0A0A), AppColors.darkPrimary],
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
                  AppColors.accentRed.withOpacity(0.2),
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
            children: [
              // Avatar
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.accentRed, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentRed.withOpacity(0.3),
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
                    if (joinedLabel != null) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.accentRed.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: AppColors.accentRed.withOpacity(0.3)),
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

              // Settings icon — navigasi ke halaman Pengaturan
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

  // ── Stats bar ────────────────────────────────────────────
  // Semua 0 — siap diganti dengan data nyata saat fitur tersedia.

  Widget _buildStats() {
    return FadeInUp(
      duration: const Duration(milliseconds: 500),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 4),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.darkSecondary,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: const Row(
          children: [
            _StatItem(value: '0', label: 'Film\nDitonton'),
            _Divider(),
            _StatItem(value: '0', label: 'Watchlist'),
            _Divider(),
            _StatItem(value: '0', label: 'Reviews'),
            _Divider(),
            _StatItem(value: '0', label: 'Mengikuti'),
          ],
        ),
      ),
    );
  }

  // ── Tab section ──────────────────────────────────────────

  Widget _buildTabSection(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          const SizedBox(height: 16),
          const TabBar(
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
              Tab(text: 'Watchlist'),
              Tab(text: 'History'),
              Tab(text: 'Taste Profile'),
              Tab(text: 'Reviews'),
            ],
          ),
          SizedBox(
            height: 320,
            child: TabBarView(
              children: [
                _buildEmptyTab(
                  icon: Icons.bookmark_border_rounded,
                  message: 'Watchlist kamu masih kosong',
                  sub: 'Tambahkan film yang ingin ditonton',
                ),
                _buildEmptyTab(
                  icon: Icons.history_rounded,
                  message: 'Belum ada riwayat tontonan',
                  sub: 'Film yang sudah ditonton akan muncul di sini',
                ),
                _buildTasteProfileTab(),
                _buildEmptyTab(
                  icon: Icons.rate_review_outlined,
                  message: 'Belum ada review',
                  sub: 'Bagikan pendapatmu tentang film yang ditonton',
                ),
              ],
            ),
          ),
        ],
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

  // ── Taste Profile tab ─────────────────────────────────────
  // Menggunakan genre asli dari profile.favoriteGenreIds

  Widget _buildTasteProfileTab() {
    final genreIds = _profile?.favoriteGenreIds ?? [];

    if (genreIds.isEmpty) {
      return _buildEmptyTab(
        icon: Icons.movie_filter_outlined,
        message: 'Belum ada data selera',
        sub: 'Pilih genre favorit di pengaturan profil',
      );
    }

    // Bagi rata persentase ke setiap genre yang dipilih
    final total = genreIds.length;
    final genres = genreIds.asMap().entries.map((e) {
      final idx = e.key;
      final id = e.value;
      final name = _kGenreNames[id] ?? 'Genre $id';
      final pct = 1.0 / total;
      final color = _kGenreColors[idx % _kGenreColors.length];
      return {'label': name, 'pct': pct, 'color': color};
    }).toList();

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
          const Text(
            'Genre favorit kamu berdasarkan pilihan saat setup.',
            style: TextStyle(
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


// ─────────────────────────────────────────────────────────
// Stat item widget
// ─────────────────────────────────────────────────────────

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

// ─────────────────────────────────────────────────────────
// Divider between stats
// ─────────────────────────────────────────────────────────

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 32, color: AppColors.border);
  }
}


// ─────────────────────────────────────────────────────────
// Donut chart painter
// ─────────────────────────────────────────────────────────

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
