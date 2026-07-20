import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:aftercredits/features/home/tabs/community/community_colors.dart';

/// Card modern untuk menampilkan satu thread diskusi.
class DiscussionCard extends StatefulWidget {
  final Map<String, dynamic> thread;
  final VoidCallback? onTap;
  final VoidCallback? onMenuTap;

  const DiscussionCard({
    super.key,
    required this.thread,
    this.onTap,
    this.onMenuTap,
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
        Container(
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
          onTap: widget.onMenuTap ?? () {},
          borderRadius: BorderRadius.circular(CommunityRadius.sm),
          child: const Padding(
            padding: EdgeInsets.all(4),
            child: Icon(Icons.more_vert_rounded, size: 18, color: CommunityColors.textMuted),
          ),
        ),
      ],
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

    return Row(
      children: [
        _StatChip(icon: Icons.arrow_upward_rounded, iconColor: CommunityColors.primary, value: _formatCount(likes)),
        const SizedBox(width: CommunitySpacing.md),
        _StatChip(icon: Icons.chat_bubble_rounded, iconColor: CommunityColors.textMuted, value: _formatCount(comments)),
        const SizedBox(width: CommunitySpacing.md),
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
