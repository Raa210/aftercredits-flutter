import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Reusable movie poster card widget
class MovieCard extends StatelessWidget {
  final String? posterUrl;
  final String title;
  final String? year;
  final double? rating;
  final VoidCallback? onTap;
  final bool showRatingBadge;
  final double? width;

  const MovieCard({
    super.key,
    required this.title,
    this.posterUrl,
    this.year,
    this.rating,
    this.onTap,
    this.showRatingBadge = true,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: width,
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
      child: Stack(
        children: [
          // Poster image
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: posterUrl != null
                ? Image.network(
                    posterUrl!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        color: AppColors.darkTertiary,
                        child: const Center(
                          child: SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                      );
                    },
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.darkTertiary,
                      child: const Center(
                        child: Icon(Icons.movie_outlined,
                            color: AppColors.textMuted, size: 24),
                      ),
                    ),
                  )
                : Container(
                    color: AppColors.darkTertiary,
                    child: const Center(
                      child: Icon(Icons.movie_outlined,
                          color: AppColors.textMuted, size: 24),
                    ),
                  ),
          ),

          // Rating badge
          if (showRatingBadge && rating != null)
            Positioned(
              top: 5,
              left: 5,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(180),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('★',
                        style:
                            TextStyle(color: AppColors.star, fontSize: 9)),
                    const SizedBox(width: 2),
                    Text(
                      rating!.toStringAsFixed(1),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
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

  Widget _buildInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (year != null)
          Text(
            year!,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
            ),
          ),
      ],
    );
  }
}
