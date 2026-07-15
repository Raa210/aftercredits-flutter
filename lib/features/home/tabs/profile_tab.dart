import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/user_profile_service.dart';
import '../../../models/user_profile_model.dart';
import '../../auth/login_screen.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  UserProfileModel? _profile;
  bool _loadingProfile = true;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
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

  // Helper to extract display name from Supabase User
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

  // Helper to get avatar URL from profile or Google metadata
  String? _avatarUrl(User user) {
    if (_profile?.avatarUrl != null && _profile!.avatarUrl!.isNotEmpty) {
      return _profile!.avatarUrl;
    }
    final meta = user.userMetadata;
    return meta?['avatar_url'] as String? ?? meta?['picture'] as String?;
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
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Header
          SliverToBoxAdapter(
              child: isGuest
                  ? _buildGuestHeader(context)
                  : _buildUserHeader(
                      _displayName(user!),
                      user.email,
                      _avatarUrl(user),
                    ),
          ),

          // Stats (only for logged in)
          if (!isGuest)
            SliverToBoxAdapter(child: _buildStats()),

          // Tab bar
          if (!isGuest)
            SliverToBoxAdapter(child: _buildTabSection(context)),

          // Settings / menu
          SliverToBoxAdapter(
            child: _buildMenuSection(context, isGuest),
          ),
        ],
      ),
    );
  }

  // ── Guest header ─────────────────────────────────────────

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
          // Avatar placeholder
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

  // ── Logged-in header ──────────────────────────────────────

  Widget _buildUserHeader(
      String? displayName, String? email, String? photoUrl) {
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
                      child: const Text(
                        'Bergabung Juni 2024',
                        style: TextStyle(
                          color: AppColors.accentRed,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Settings icon
              IconButton(
                icon: const Icon(Icons.settings_outlined,
                    color: AppColors.textSecondary),
                onPressed: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Stats bar ─────────────────────────────────────────────

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
        child: Row(
          children: [
            _StatItem(value: '42', label: 'Film\nDitonton'),
            _buildDivider(),
            _StatItem(value: '18', label: 'Film\nTerdaftar'),
            _buildDivider(),
            _StatItem(value: '32', label: 'Reviews'),
            _buildDivider(),
            _StatItem(value: '27', label: 'Mengikuti'),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 32,
      color: AppColors.border,
    );
  }

  // ── Tab section ───────────────────────────────────────────

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
                _buildWatchlistTab(),
                _buildHistoryTab(),
                _buildTasteProfileTab(),
                _buildReviewsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWatchlistTab() {
    return const Center(
      child: Text(
        'Belum ada film di watchlist',
        style: TextStyle(color: AppColors.textMuted),
      ),
    );
  }

  Widget _buildHistoryTab() {
    return const Center(
      child: Text(
        'Belum ada riwayat tontonan',
        style: TextStyle(color: AppColors.textMuted),
      ),
    );
  }

  Widget _buildTasteProfileTab() {
    // Genre taste donut-like visualization
    final genres = [
      {'label': 'Action', 'pct': 0.70, 'color': AppColors.accentRed},
      {'label': 'Sci-Fi', 'pct': 0.20, 'color': const Color(0xFF0EA5E9)},
      {'label': 'Drama', 'pct': 0.10, 'color': const Color(0xFF7C3AED)},
    ];

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
          const SizedBox(height: 6),
          const Text(
            'Ini adalah analisis selera kamu berdasarkan\nfilm yang telah kamu tonton.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              // Donut chart placeholder
              SizedBox(
                width: 100,
                height: 100,
                child: CustomPaint(painter: _DonutChartPainter(genres)),
              ),
              const SizedBox(width: 24),
              // Legend
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: genres.map((g) {
                  final color = g['color'] as Color;
                  final pct = ((g['pct'] as double) * 100).toInt();
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
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
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsTab() {
    return const Center(
      child: Text(
        'Belum ada review',
        style: TextStyle(color: AppColors.textMuted),
      ),
    );
  }

  // ── Menu / settings section ────────────────────────────────

  Widget _buildMenuSection(BuildContext context, bool isGuest) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pengaturan',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          _MenuTile(
            icon: Icons.notifications_outlined,
            label: 'Notifikasi',
            onTap: () {},
          ),
          _MenuTile(
            icon: Icons.lock_outline_rounded,
            label: 'Privasi',
            onTap: () {},
          ),
          _MenuTile(
            icon: Icons.help_outline_rounded,
            label: 'Bantuan & FAQ',
            onTap: () {},
          ),
          _MenuTile(
            icon: Icons.info_outline_rounded,
            label: 'Tentang AfterCredits',
            onTap: () {},
          ),
          if (!isGuest) ...[
            const SizedBox(height: 8),
            const Divider(color: AppColors.border, thickness: 0.5),
            const SizedBox(height: 8),
            _MenuTile(
              icon: Icons.logout_rounded,
              label: 'Keluar',
              labelColor: AppColors.accentRed,
              onTap: () async {
                await AuthService().signOut();
                if (context.mounted) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const AuthScreen()),
                  );

                }
              },
            ),
          ],
          const SizedBox(height: 32),
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
// Menu tile widget
// ─────────────────────────────────────────────────────────

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? labelColor;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.darkTertiary,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 18,
          color: labelColor ?? AppColors.textSecondary,
        ),
      ),
      title: Text(
        label,
        style: TextStyle(
          color: labelColor ?? AppColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppColors.textMuted,
        size: 18,
      ),
      onTap: onTap,
    );
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
    var startAngle = -3.14159 / 2;

    for (final item in data) {
      final sweep = (item['pct'] as double) * 2 * 3.14159;
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
