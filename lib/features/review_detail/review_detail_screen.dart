import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:animate_do/animate_do.dart';
import 'package:aftercredits/core/theme/app_theme.dart';
import 'package:aftercredits/models/community_review_model.dart';
import 'package:aftercredits/models/movie_model.dart';
import 'package:aftercredits/core/services/review_community_service.dart';
import 'package:aftercredits/core/services/tmdb_service.dart';
import 'package:aftercredits/features/movie_detail/movie_detail_screen.dart';

class ReviewDetailScreen extends StatefulWidget {
  final CommunityReviewModel review;

  const ReviewDetailScreen({super.key, required this.review});

  @override
  State<ReviewDetailScreen> createState() => _ReviewDetailScreenState();
}

class _ReviewDetailScreenState extends State<ReviewDetailScreen> {
  final ReviewCommunityService _communityService = ReviewCommunityService();
  final TmdbService _tmdb = TmdbService();
  final TextEditingController _commentController = TextEditingController();

  MovieModel? _movieDetail;
  bool _loadingMovie = true;

  bool _isLiked = false;
  int _likesCount = 0;
  List<Map<String, dynamic>> _comments = [];
  bool _submittingComment = false;

  @override
  void initState() {
    super.initState();
    _likesCount = widget.review.likesCount;
    _loadMovie();
    _loadState();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadMovie() async {
    final m = await _tmdb.getMovieDetails(widget.review.movieId);
    if (!mounted) return;
    setState(() {
      _movieDetail = m;
      _loadingMovie = false;
    });
  }

  Future<void> _loadState() async {
    final liked = await _communityService.isReviewLiked(widget.review.id);
    final comments = await _communityService.getComments(widget.review.id);
    if (!mounted) return;
    setState(() {
      _isLiked = liked;
      _comments = comments;
    });
  }

  Future<void> _toggleLike() async {
    HapticFeedback.lightImpact();
    final liked = await _communityService.toggleLikeReview(widget.review.id);
    if (!mounted) return;
    setState(() {
      _isLiked = liked;
      _likesCount = _likesCount + (liked ? 1 : -1);
    });
  }

  Future<void> _postComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    setState(() => _submittingComment = true);
    await _communityService.addComment(widget.review.id, text);
    _commentController.clear();
    
    // Reload comments
    final comments = await _communityService.getComments(widget.review.id);
    if (!mounted) return;
    setState(() {
      _comments = comments;
      _submittingComment = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Komentar berhasil diposting ✓', style: TextStyle(color: Colors.white, fontSize: 13)),
        backgroundColor: AppColors.darkTertiary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _openMovieDetail() {
    if (_movieDetail == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => MovieDetailScreen(movie: _movieDetail!)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.darkPrimary,
        title: const Text('Review Detail', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Movie tiny card
                  _buildMovieCard(),
                  const SizedBox(height: 20),

                  // Review content card
                  _buildReviewCard(),
                  const SizedBox(height: 24),

                  // Comments header
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 16,
                        decoration: BoxDecoration(
                          color: AppColors.accentRed,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Komentar (${_comments.length})',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Comments list
                  _buildCommentsList(),
                ],
              ),
            ),
          ),

          // Comment input at bottom
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildMovieCard() {
    if (_loadingMovie) {
      return Container(
        height: 70,
        decoration: BoxDecoration(
          color: AppColors.darkSecondary,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(color: AppColors.accentRed, strokeWidth: 2),
        ),
      );
    }

    if (_movieDetail == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: _openMovieDetail,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.darkSecondary,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _movieDetail!.posterUrl != null
                  ? Image.network(_movieDetail!.posterUrl!, width: 40, height: 60, fit: BoxFit.cover)
                  : Container(width: 40, height: 60, color: AppColors.darkTertiary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _movieDetail!.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_movieDetail!.year}  •  ★ ${_movieDetail!.ratingFormatted}',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textMuted, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewCard() {
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
          // Author Header
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.darkTertiary,
                backgroundImage: widget.review.authorAvatar != null
                    ? NetworkImage(widget.review.authorAvatar!)
                    : null,
                child: widget.review.authorAvatar == null
                    ? Text(widget.review.authorName.isNotEmpty ? widget.review.authorName[0].toUpperCase() : '?',
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold))
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '@${widget.review.authorName}',
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(widget.review.timeLabel, style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
                  ],
                ),
              ),
              // Stars
              Row(
                children: List.generate(5, (i) {
                  final isFull = widget.review.rating >= i + 1;
                  return Icon(
                    isFull ? Icons.star_rounded : Icons.star_border_rounded,
                    color: isFull ? AppColors.star : AppColors.border,
                    size: 14,
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Teks review
          Text(
            widget.review.text,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 16),

          const Divider(color: AppColors.border, height: 1, thickness: 0.5),
          const SizedBox(height: 12),

          // Like Button & Info Row
          GestureDetector(
            onTap: _toggleLike,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: _isLiked ? AppColors.accentRed : AppColors.textMuted,
                  size: 20,
                ),
                const SizedBox(width: 6),
                Text(
                  '$_likesCount Like',
                  style: TextStyle(
                    color: _isLiked ? AppColors.accentRed : AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsList() {
    if (_comments.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 32),
        width: double.infinity,
        alignment: Alignment.center,
        child: const Column(
          children: [
            Icon(Icons.chat_bubble_outline_rounded, color: AppColors.textMuted, size: 28),
            SizedBox(height: 8),
            Text(
              'Belum ada komentar',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 2),
            Text(
              'Jadilah yang pertama untuk memulai diskusi!',
              style: TextStyle(color: AppColors.textMuted, fontSize: 11),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _comments.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final c = _comments[index];
        final author = c['author'] as String? ?? 'User';
        final avatar = c['avatar'] as String?;
        final content = c['content'] as String? ?? '';
        final time = c['time'] as String? ?? '';

        return FadeInRight(
          delay: Duration(milliseconds: 30 * index),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.darkSecondary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: AppColors.darkTertiary,
                      backgroundImage: avatar != null ? NetworkImage(avatar) : null,
                      child: avatar == null
                          ? Text(author[0].toUpperCase(),
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '@$author',
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                    const Spacer(),
                    Text(time, style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  content,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInputBar() {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, bottomInset > 0 ? bottomInset + 8 : 12),
      decoration: BoxDecoration(
        color: AppColors.darkSecondary,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(50),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
        border: const Border(top: BorderSide(color: AppColors.border, width: 0.6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              constraints: const BoxConstraints(minHeight: 46, maxHeight: 120),
              decoration: BoxDecoration(
                color: AppColors.darkTertiary,
                borderRadius: BorderRadius.circular(23),
                border: Border.all(color: AppColors.border, width: 0.8),
              ),
              child: TextField(
                controller: _commentController,
                minLines: 1,
                maxLines: 4,
                textAlignVertical: TextAlignVertical.center,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                decoration: const InputDecoration(
                  isDense: true,
                  hintText: 'Tulis komentar/balasan...',
                  hintStyle: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _submittingComment ? null : _postComment,
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.accentRed,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentRed.withAlpha(80),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: _submittingComment
                  ? const Center(
                      child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2)),
                    )
                  : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
