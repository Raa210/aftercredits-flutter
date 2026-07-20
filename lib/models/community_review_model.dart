class CommunityReviewModel {
  final String id;
  final int movieId;
  final String movieTitle;
  final String? posterUrl;
  final String authorName;
  final String? authorAvatar;
  final String? authorId;
  final double rating;
  final String text;
  final int likesCount;
  final String timeLabel;
  final bool isUserReview;

  const CommunityReviewModel({
    required this.id,
    required this.movieId,
    required this.movieTitle,
    this.posterUrl,
    required this.authorName,
    this.authorAvatar,
    this.authorId,
    required this.rating,
    required this.text,
    required this.likesCount,
    required this.timeLabel,
    this.isUserReview = false,
  });

  CommunityReviewModel copyWith({
    String? id,
    int? movieId,
    String? movieTitle,
    String? posterUrl,
    String? authorName,
    String? authorAvatar,
    String? authorId,
    double? rating,
    String? text,
    int? likesCount,
    String? timeLabel,
    bool? isUserReview,
  }) {
    return CommunityReviewModel(
      id: id ?? this.id,
      movieId: movieId ?? this.movieId,
      movieTitle: movieTitle ?? this.movieTitle,
      posterUrl: posterUrl ?? this.posterUrl,
      authorName: authorName ?? this.authorName,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      authorId: authorId ?? this.authorId,
      rating: rating ?? this.rating,
      text: text ?? this.text,
      likesCount: likesCount ?? this.likesCount,
      timeLabel: timeLabel ?? this.timeLabel,
      isUserReview: isUserReview ?? this.isUserReview,
    );
  }
}
