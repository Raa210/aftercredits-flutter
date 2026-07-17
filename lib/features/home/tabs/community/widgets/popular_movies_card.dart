import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../community_colors.dart';

/// Sidebar card "Film Populer Minggu Ini".
///
/// Grid 4 poster film dengan badge ranking di pojok kiri bawah.
class PopularMoviesCard extends StatelessWidget {
  final List<Map<String, dynamic>> movies;
  final VoidCallback? onViewAll;

  const PopularMoviesCard({
    super.key,
    required this.movies,
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
                const Text(
                  '🍿',
                  style: TextStyle(fontSize: 18),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Film Populer Minggu Ini',
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

          // ─── Poster Grid ────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: List.generate(
                movies.length > 4 ? 4 : movies.length,
                (index) => Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: index > 0 ? 8 : 0,
                    ),
                    child: _PosterWithRank(
                      rank: index + 1,
                      movie: movies[index],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PosterWithRank extends StatefulWidget {
  final int rank;
  final Map<String, dynamic> movie;

  const _PosterWithRank({
    required this.rank,
    required this.movie,
  });

  @override
  State<_PosterWithRank> createState() => _PosterWithRankState();
}

class _PosterWithRankState extends State<_PosterWithRank> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: _isHovered
            ? (Matrix4.identity()..scale(1.05))
            : Matrix4.identity(),
        transformAlignment: Alignment.center,
        child: AspectRatio(
          aspectRatio: 2 / 3,
          child: Stack(
            children: [
              // ─── Poster ──────────────────────────
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(CommunityRadius.md),
                  child: _buildPoster(),
                ),
              ),

              // ─── Gradient Overlay ────────────────
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(CommunityRadius.md),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                        stops: const [0.5, 1.0],
                      ),
                    ),
                  ),
                ),
              ),

              // ─── Ranking Badge ───────────────────
              Positioned(
                left: 6,
                bottom: 6,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: CommunityColors.primary,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: CommunityColors.primary.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${widget.rank}',
                    style: const TextStyle(
                      color: CommunityColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPoster() {
    final posterUrl = widget.movie['posterUrl'] as String?;
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
      child: const Center(
        child: Icon(
          Icons.movie_creation_outlined,
          color: CommunityColors.textMuted,
          size: 24,
        ),
      ),
    );
  }
}
