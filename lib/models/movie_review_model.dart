/// Model untuk review film yang ditulis oleh user.
/// Disimpan secara lokal via SharedPreferences.
class MovieReview {
  final int movieId;
  final double rating; // 0.5 – 5.0, increment 0.5
  final String text;
  final DateTime createdAt;

  const MovieReview({
    required this.movieId,
    required this.rating,
    required this.text,
    required this.createdAt,
  });

  factory MovieReview.fromJson(Map<String, dynamic> json) {
    return MovieReview(
      movieId: json['movieId'] as int,
      rating: (json['rating'] as num).toDouble(),
      text: json['text'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'movieId': movieId,
        'rating': rating,
        'text': text,
        'createdAt': createdAt.toIso8601String(),
      };

  MovieReview copyWith({
    int? movieId,
    double? rating,
    String? text,
    DateTime? createdAt,
  }) {
    return MovieReview(
      movieId: movieId ?? this.movieId,
      rating: rating ?? this.rating,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
