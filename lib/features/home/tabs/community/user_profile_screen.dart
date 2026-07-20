import 'package:flutter/material.dart';
import 'package:aftercredits/core/theme/app_theme.dart';
import 'package:aftercredits/core/services/auth_service.dart';
import 'package:aftercredits/core/services/follow_service.dart';
import 'package:aftercredits/core/services/user_profile_service.dart';
import 'package:aftercredits/core/services/community_service.dart';
import 'package:aftercredits/models/user_profile_model.dart';
import 'community_colors.dart';
import 'thread_detail_screen.dart';

/// Layar untuk melihat profil pengguna lain dari komunitas.
/// Menampilkan info profil, jumlah followers/following, dan tombol follow/unfollow.
class UserProfileScreen extends StatefulWidget {
  final String userId;
  final String username;
  final String? avatarUrl;

  const UserProfileScreen({
    super.key,
    required this.userId,
    required this.username,
    this.avatarUrl,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  UserProfileModel? _profile;
  bool _isFollowing = false;
  bool _followLoading = false;
  int _followersCount = 0;
  int _followingCount = 0;
  List<Map<String, dynamic>> _userThreads = [];
  bool _loadingThreads = true;

  bool get _isOwnProfile =>
      AuthService().currentUser?.id == widget.userId;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    await Future.wait([
      _fetchProfile(),
      _fetchFollowStatus(),
      _fetchFollowCounts(),
      _fetchUserThreads(),
    ]);
  }

  Future<void> _fetchProfile() async {
    try {
      final profile = await UserProfileService().getProfile(widget.userId);
      if (mounted) setState(() => _profile = profile);
    } catch (_) {}
  }

  Future<void> _fetchFollowStatus() async {
    if (_isOwnProfile) return;
    try {
      final following = await FollowService().isFollowing(widget.userId);
      if (mounted) setState(() => _isFollowing = following);
    } catch (_) {}
  }

  Future<void> _fetchFollowCounts() async {
    try {
      final counts = await FollowService().getFollowCounts(widget.userId);
      if (mounted) {
        setState(() {
          _followersCount = counts.followers;
          _followingCount = counts.following;
        });
      }
    } catch (_) {}
  }

  Future<void> _fetchUserThreads() async {
    try {
      final threads = await CommunityService().getThreadsByUser(widget.userId);
      if (mounted) setState(() => _userThreads = threads);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingThreads = false);
    }
  }

  Future<void> _toggleFollow() async {
    if (_followLoading) return;
    setState(() => _followLoading = true);

    final targetFollow = !_isFollowing;
    setState(() {
      _isFollowing = targetFollow;
      _followersCount = targetFollow ? _followersCount + 1 : _followersCount - 1;
    });

    try {
      if (targetFollow) {
        await FollowService().followUser(widget.userId);
      } else {
        await FollowService().unfollowUser(widget.userId);
      }
    } catch (e) {
      // Revert on error
      setState(() {
        _isFollowing = !targetFollow;
        _followersCount = !targetFollow ? _followersCount + 1 : _followersCount - 1;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: CommunityColors.primary,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _followLoading = false);
    }
  }

  String _formatJoined(DateTime dt) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
    ];
    return 'Bergabung ${months[dt.month - 1]} ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkPrimary,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ─── App Bar + Header ─────────────────────────────
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppColors.darkPrimary,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: AppColors.textPrimary, size: 18),
              onPressed: () => Navigator.of(context).pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: _buildHeader(),
            ),
          ),

          // ─── Stats Row ────────────────────────────────────
          SliverToBoxAdapter(child: _buildStatsRow()),

          // ─── Threads Section ──────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
              child: Text(
                'Diskusi',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),

          if (_loadingThreads)
            const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: CommunityColors.primary,
                  ),
                ),
              ),
            )
          else if (_userThreads.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    Icon(Icons.chat_bubble_outline_rounded,
                        color: AppColors.textMuted, size: 36),
                    const SizedBox(height: 12),
                    Text(
                      'Belum ada diskusi',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildThreadCard(_userThreads[index]),
                  childCount: _userThreads.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final avatarUrl = widget.avatarUrl ?? _profile?.avatarUrl;
    final username = '@${widget.username}';
    final joinedLabel = _profile != null ? _formatJoined(_profile!.createdAt) : null;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A0808), AppColors.darkPrimary],
        ),
      ),
      child: Stack(
        children: [
          // Red glow accent
          Positioned(
            top: -30,
            left: -30,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    AppColors.accentRed.withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 48, 20, 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Avatar
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _isOwnProfile
                            ? AppColors.accentRed
                            : CommunityColors.primary,
                        width: 2.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (_isOwnProfile
                                  ? AppColors.accentRed
                                  : CommunityColors.primary)
                              .withValues(alpha: 0.25),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: AppColors.darkTertiary,
                      backgroundImage:
                          avatarUrl != null ? NetworkImage(avatarUrl) : null,
                      child: avatarUrl == null
                          ? Text(
                              widget.username.isNotEmpty
                                  ? widget.username[0].toUpperCase()
                                  : 'U',
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

                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          username,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (joinedLabel != null) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.accentRed.withValues(alpha: 0.12),
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
                        const SizedBox(height: 10),

                        // Follow/Unfollow Button (hanya tampil jika bukan profil sendiri)
                        if (!_isOwnProfile)
                          _buildFollowButton(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFollowButton() {
    return GestureDetector(
      onTap: _toggleFollow,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: _isFollowing
              ? Colors.transparent
              : CommunityColors.primary,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _isFollowing
                ? AppColors.border
                : CommunityColors.primary,
            width: 1.5,
          ),
        ),
        child: _followLoading
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isFollowing
                        ? Icons.person_remove_outlined
                        : Icons.person_add_outlined,
                    size: 14,
                    color: _isFollowing
                        ? AppColors.textSecondary
                        : Colors.white,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _isFollowing ? 'Mengikuti' : 'Ikuti',
                    style: TextStyle(
                      color: _isFollowing
                          ? AppColors.textSecondary
                          : Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.darkSecondary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          _StatChip(value: '$_followersCount', label: 'Pengikut'),
          Container(width: 1, height: 28, color: AppColors.border),
          _StatChip(value: '$_followingCount', label: 'Mengikuti'),
          Container(width: 1, height: 28, color: AppColors.border),
          _StatChip(value: '${_userThreads.length}', label: 'Diskusi'),
        ],
      ),
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
            // Tag
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

            // Title
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

            // Footer stats
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
}

// ─── Helper widget ────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final String value;
  final String label;

  const _StatChip({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
