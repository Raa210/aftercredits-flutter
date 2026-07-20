import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:aftercredits/features/home/tabs/community/community_colors.dart';
import 'package:aftercredits/core/theme/app_theme.dart';
import 'package:aftercredits/core/services/auth_service.dart';
import 'package:aftercredits/core/services/community_service.dart';
import 'package:aftercredits/features/home/tabs/community/user_profile_screen.dart';

/// Card modern untuk menampilkan satu thread diskusi.
class DiscussionCard extends StatefulWidget {
  final Map<String, dynamic> thread;
  final VoidCallback? onTap;
  final VoidCallback? onMenuTap;
  final VoidCallback? onDelete;

  const DiscussionCard({
    super.key,
    required this.thread,
    this.onTap,
    this.onMenuTap,
    this.onDelete,
  });

  @override
  State<DiscussionCard> createState() => _DiscussionCardState();
}

class _DiscussionCardState extends State<DiscussionCard> {
  bool _isHovered = false;
  bool _spoilerRevealed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap ?? () {},
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          transform: (kIsWeb && _isHovered)
              ? (Matrix4.identity()..scale(1.01))
              : Matrix4.identity(),
          transformAlignment: Alignment.center,
          decoration: BoxDecoration(
            color: _isHovered ? CommunityColors.cardHover : CommunityColors.card,
            borderRadius: BorderRadius.circular(CommunityRadius.lg),
            border: Border.all(
              color: _isHovered
                  ? CommunityColors.divider.withOpacity(0.8)
                  : CommunityColors.divider.withOpacity(0.4),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_isHovered ? 0.4 : 0.2),
                blurRadius: _isHovered ? 24 : 8,
                offset: Offset(0, _isHovered ? 8 : 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Poster Film ─────────────────────
                _buildPoster(),
                const SizedBox(width: CommunitySpacing.md),

                // ─── Content ─────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTopRow(),
                      const SizedBox(height: CommunitySpacing.xs),
                      _buildAuthorRow(),
                      const SizedBox(height: CommunitySpacing.sm),
                      _buildTitle(),
                      const SizedBox(height: CommunitySpacing.xs),
                      _buildSpoilerOrDescription(),
                      const SizedBox(height: CommunitySpacing.md),
                      _buildStats(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPoster() {
    final posterUrl = widget.thread['posterUrl'] as String?;
    return ClipRRect(
      borderRadius: BorderRadius.circular(CommunityRadius.md),
      child: SizedBox(
        width: 80,
        height: 120,
        child: posterUrl != null && posterUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: posterUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => _buildPosterPlaceholder(),
                errorWidget: (_, __, ___) => _buildPosterPlaceholder(),
              )
            : _buildPosterPlaceholder(),
      ),
    );
  }

  Widget _buildPosterPlaceholder() {
    return Container(
      color: CommunityColors.divider,
      child: const Center(
        child: Icon(Icons.movie_creation_outlined, color: CommunityColors.textMuted, size: 28),
      ),
    );
  }

  Widget _buildTopRow() {
    final tag = widget.thread['tag'] as String;
    final tagColor = Color(widget.thread['tagColor'] as int);
    final time = widget.thread['time'] as String;

    return Row(
      children: [
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: tagColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(CommunityRadius.sm),
              border: Border.all(color: tagColor.withOpacity(0.3), width: 0.5),
            ),
            child: Text(
              tag,
              style: TextStyle(
                color: tagColor,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        const Spacer(),
        Icon(Icons.access_time_rounded, size: 13, color: CommunityColors.textMuted),
        const SizedBox(width: 4),
        Text(
          time,
          style: const TextStyle(color: CommunityColors.textMuted, fontSize: 12, fontWeight: FontWeight.w400),
        ),
        const SizedBox(width: 4),
        InkWell(
          onTap: widget.onMenuTap ?? _handleMenuTap,
          borderRadius: BorderRadius.circular(CommunityRadius.sm),
          child: const Padding(
            padding: EdgeInsets.all(4),
            child: Icon(Icons.more_vert_rounded, size: 18, color: CommunityColors.textMuted),
          ),
        ),
      ],
    );
  }

  void _openUserProfile() {
    final authorId = widget.thread['author_id'] as String? ?? '';
    final authorName = widget.thread['author'] as String? ?? '';
    final avatarUrl = widget.thread['author_avatar'] as String?;
    if (authorId.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => UserProfileScreen(
          userId: authorId,
          username: authorName,
          avatarUrl: avatarUrl,
        ),
      ),
    );
  }

  void _handleMenuTap() {
    final authorId = widget.thread['author_id'] as String? ?? '';
    final currentUserId = AuthService().currentUser?.id;
    final isAuthor = currentUserId != null && authorId == currentUserId;

    showModalBottomSheet(
      context: context,
      backgroundColor: CommunityColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isAuthor) ...[
              ListTile(
                leading: Icon(Icons.delete_outline_rounded, color: AppColors.accentRed),
                title: Text('Hapus Diskusi', style: TextStyle(color: AppColors.accentRed, fontWeight: FontWeight.w600)),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  _confirmDelete();
                },
              ),
            ],
            ListTile(
              leading: const Icon(Icons.person_outline_rounded, color: AppColors.textPrimary),
              title: Text('Lihat Profil @${widget.thread['author']}', style: const TextStyle(color: AppColors.textPrimary)),
              onTap: () {
                Navigator.pop(sheetContext);
                _openUserProfile();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CommunityColors.card,
        title: Text('Hapus Diskusi?', style: TextStyle(color: AppColors.textPrimary)),
        content: Text('Apakah Anda yakin ingin menghapus diskusi ini? Tindakan ini tidak dapat dibatalkan.', style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final id = widget.thread['id'] as String;
                await CommunityService().deleteThread(id);
                widget.onDelete?.call();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Diskusi berhasil dihapus', style: TextStyle(color: AppColors.textPrimary)),
                      backgroundColor: AppColors.darkTertiary,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Gagal menghapus diskusi: $e', style: TextStyle(color: AppColors.textPrimary)),
                      backgroundColor: AppColors.accentRed,
                    ),
                  );
                }
              }
            },
            child: Text('Hapus', style: TextStyle(color: AppColors.accentRed, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthorRow() {
    final authorName = widget.thread['author'] as String? ?? 'Anonymous';
    final avatarUrl = widget.thread['author_avatar'] as String?;

    return GestureDetector(
      onTap: _openUserProfile,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          CircleAvatar(
            radius: 11,
            backgroundColor: CommunityColors.divider,
            backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                ? CachedNetworkImageProvider(avatarUrl)
                : null,
            child: (avatarUrl == null || avatarUrl.isEmpty)
                ? Text(
                    authorName.isNotEmpty ? authorName[0].toUpperCase() : '?',
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 10, fontWeight: FontWeight.w700),
                  )
                : null,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              '@$authorName',
              style: const TextStyle(
                color: CommunityColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      widget.thread['title'] as String,
      style: const TextStyle(
        color: CommunityColors.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w700,
        height: 1.3,
        letterSpacing: -0.2,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildDescription() {
    return Text(
      widget.thread['preview'] as String,
      style: const TextStyle(
        color: CommunityColors.textSecondary,
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 1.5,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildSpoilerOrDescription() {
    final isSpoiler = (widget.thread['tag'] as String?)?.toUpperCase() == 'SPOILER';
    if (!isSpoiler) return _buildDescription();

    return GestureDetector(
      onTap: () => setState(() => _spoilerRevealed = !_spoilerRevealed),
      child: Stack(
        alignment: Alignment.center,
        children: [
          ImageFiltered(
            imageFilter: _spoilerRevealed
                ? ImageFilter.blur(sigmaX: 0, sigmaY: 0)
                : ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: Text(
              widget.thread['preview'] as String,
              style: const TextStyle(
                color: CommunityColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w400,
                height: 1.5,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (!_spoilerRevealed)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.65),
                borderRadius: BorderRadius.circular(CommunityRadius.pill),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.visibility_off_rounded, size: 12, color: Colors.white),
                  SizedBox(width: 4),
                  Text('Tap untuk lihat spoiler',
                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
        ],
      ),
    );
  }


  Widget _buildStats() {
    final likes = widget.thread['likes'] as int;
    final comments = widget.thread['comments'] as int;
    final views = widget.thread['views'] as int? ?? 0;

    return Wrap(
      spacing: 14,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _StatChip(icon: Icons.arrow_upward_rounded, iconColor: CommunityColors.primary, value: _formatCount(likes)),
        _StatChip(icon: Icons.chat_bubble_rounded, iconColor: CommunityColors.textMuted, value: _formatCount(comments)),
        _StatChip(icon: Icons.visibility_rounded, iconColor: CommunityColors.textMuted, value: _formatCount(views)),
      ],
    );
  }

  String _formatCount(int count) {
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;

  const _StatChip({required this.icon, required this.iconColor, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: iconColor),
        const SizedBox(width: 4),
        Text(value, style: const TextStyle(color: CommunityColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
