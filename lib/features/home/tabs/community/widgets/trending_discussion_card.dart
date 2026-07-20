import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:aftercredits/features/home/tabs/community/community_colors.dart';

/// Sidebar card "Trending Discussion".
///
/// Menampilkan top 5 thread dengan ranking, poster kecil,
/// judul, likes, dan comments.
class TrendingDiscussionCard extends StatelessWidget {
  final List<Map<String, dynamic>> threads;
  final VoidCallback? onViewAll;

  const TrendingDiscussionCard({
    super.key,
    required this.threads,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CommunityColors.card,
        borderRadius: BorderRadius.circular(CommunityRadius.lg),
        border: Border.all(
          color: CommunityColors.divider.withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Header ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(
              children: [
                const Icon(
                  Icons.trending_up_rounded,
                  color: CommunityColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Trending Discussion',
                    style: TextStyle(
                      color: CommunityColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: onViewAll ?? () {},
                  child: const Text(
                    'Lihat semua',
                    style: TextStyle(
                      color: CommunityColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ─── Divider ────────────────────────────────
          const Divider(
            color: CommunityColors.divider,
            height: 1,
            thickness: 1,
          ),

          // ─── Items ──────────────────────────────────
          ...List.generate(
            threads.length > 5 ? 5 : threads.length,
            (index) => _TrendingItem(
              rank: index + 1,
              thread: threads[index],
              isLast: index == (threads.length > 5 ? 4 : threads.length - 1),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendingItem extends StatefulWidget {
  final int rank;
  final Map<String, dynamic> thread;
  final bool isLast;

  const _TrendingItem({
    required this.rank,
    required this.thread,
    required this.isLast,
  });

  @override
  State<_TrendingItem> createState() => _TrendingItemState();
}

class _TrendingItemState extends State<_TrendingItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        color: _isHovered
            ? CommunityColors.cardHover
            : Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              // ─── Ranking ──────────────────────
              SizedBox(
                width: 24,
                child: Text(
                  '${widget.rank}',
                  style: TextStyle(
                    color: widget.rank <= 3
                        ? CommunityColors.primary
                        : CommunityColors.textMuted,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // ─── Poster Kecil ─────────────────
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  width: 40,
                  height: 56,
                  child: _buildPoster(),
                ),
              ),
              const SizedBox(width: 12),

              // ─── Info ─────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.thread['title'] as String,
                      style: const TextStyle(
                        color: CommunityColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.favorite_rounded,
                          size: 12,
                          color: CommunityColors.primary,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          _formatCount(widget.thread['likes'] as int),
                          style: const TextStyle(
                            color: CommunityColors.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.chat_bubble_rounded,
                          size: 12,
                          color: CommunityColors.textMuted,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          _formatCount(widget.thread['comments'] as int),
                          style: const TextStyle(
                            color: CommunityColors.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPoster() {
    final posterUrl = widget.thread['posterUrl'] as String?;
    if (posterUrl != null && posterUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: posterUrl,
        fit: BoxFit.cover,
        placeholder: (_, __) => _placeholder(),
        errorWidget: (_, __, ___) => _placeholder(),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      color: CommunityColors.divider,
      child: const Icon(
        Icons.movie_creation_outlined,
        color: CommunityColors.textMuted,
        size: 16,
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}
