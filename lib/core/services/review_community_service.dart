import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aftercredits/models/community_review_model.dart';
import 'package:aftercredits/core/services/movie_user_data_service.dart';
import 'package:aftercredits/core/services/auth_service.dart';

class ReviewCommunityService {
  static final ReviewCommunityService _instance = ReviewCommunityService._internal();
  factory ReviewCommunityService() => _instance;
  ReviewCommunityService._internal();

  static const _keyLikedReviews = 'user_liked_reviews';
  static const _keyReviewComments = 'user_review_comments';

  // ─── Predefined Mock Reviews ───────────────────────────────
  final List<CommunityReviewModel> _mockReviews = [
    const CommunityReviewModel(
      id: 'mock_rev_1',
      movieId: 27205, // Inception
      movieTitle: 'Inception',
      posterUrl: 'https://image.tmdb.org/t/p/w185/ljsZTbVsrQSqNgWeRnEkekVgiOfH.jpg',
      authorName: 'alex_cinema',
      authorAvatar: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=80',
      rating: 5.0,
      text: 'Film ini benar-benar mahakarya! Konsep mimpi di dalam mimpi dieksekusi dengan sangat cerdas oleh Nolan. Musik dari Hans Zimmer membuat atmosfer ketegangannya luar biasa. Plot twist di bagian akhir masih membuat saya berdebat sampai sekarang.',
      likesCount: 142,
      timeLabel: '2 hari lalu',
    ),
    const CommunityReviewModel(
      id: 'mock_rev_2',
      movieId: 157336, // Interstellar
      movieTitle: 'Interstellar',
      posterUrl: 'https://image.tmdb.org/t/p/w185/gEU2QniE6E77NI6lCU6MxlNBvIx.jpg',
      authorName: 'diana_movies',
      authorAvatar: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=80',
      rating: 4.5,
      text: 'Visual luar angkasa yang menakjubkan digabung dengan drama keluarga yang sangat menyentuh hati. Hubungan Cooper dan Murph adalah ruh dari film sci-fi ilmiah ini. Adegan perpustakaan dimensi kelima selalu membuat saya merinding.',
      likesCount: 98,
      timeLabel: '3 hari lalu',
    ),
    const CommunityReviewModel(
      id: 'mock_rev_3',
      movieId: 496243, // Parasite
      movieTitle: 'Parasite',
      posterUrl: 'https://image.tmdb.org/t/p/w185/7IiTTgloJzvGI1TAYymCfbfl3vT.jpg',
      authorName: 'sutan_film',
      authorAvatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=80',
      rating: 5.0,
      text: 'Perpaduan genre komedi hitam dan thriller sosial yang sempurna dari Bong Joon Ho. Ketimpangan kelas digambarkan secara satir namun sangat realistis. Setiap sudut rumah mewah itu memiliki detail metafora yang luar biasa.',
      likesCount: 115,
      timeLabel: '5 hari lalu',
    ),
    const CommunityReviewModel(
      id: 'mock_rev_4',
      movieId: 335984, // Blade Runner 2049
      movieTitle: 'Blade Runner 2049',
      posterUrl: 'https://image.tmdb.org/t/p/w185/gajva2L0rPYkEWjzgFlBXCAVBE5.jpg',
      authorName: 'budi_cinephile',
      authorAvatar: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=80',
      rating: 4.0,
      text: 'Secara visual, ini adalah salah satu film terindah dekade ini. Sinematografi Roger Deakins sangat memukau. Alurnya memang lambat (slow-burn), tapi membangun emosi dan filsafat eksistensialisme replikan dengan sangat mendalam.',
      likesCount: 64,
      timeLabel: '1 minggu lalu',
    ),
  ];

  // ─── Fetch Popular Reviews ────────────────────────────────
  
  Future<List<CommunityReviewModel>> getPopularReviews() async {
    final list = <CommunityReviewModel>[];
    
    // 1. Ambil review milik user sendiri (jika ada)
    final userDataService = MovieUserDataService();
    final userReviews = await userDataService.getAllReviews();
    final currentUser = AuthService().currentUser;
    
    // Gunakan info username jika ada
    final username = currentUser?.email?.split('@').first ?? 'Kamu';

    for (final entry in userReviews.entries) {
      final rev = entry.value;
      // Ambil detail poster minimal (atau bisa kosong, detail page akan meload detail TMDB)
      list.add(CommunityReviewModel(
        id: 'user_rev_${rev.movieId}',
        movieId: rev.movieId,
        movieTitle: 'Film #${rev.movieId}', // Fallback title
        authorName: username,
        rating: rev.rating,
        text: rev.text,
        likesCount: 0, // Like awal ulasan user
        timeLabel: 'Baru saja',
        isUserReview: true,
      ));
    }

    // 2. Gabungkan dengan mock reviews
    list.addAll(_mockReviews);

    // 3. Tambahkan status likes yang tersimpan di lokal ke setiap item
    final likedIds = await getLikedReviewIds();
    final results = list.map((r) {
      final isLiked = likedIds.contains(r.id);
      return r.copyWith(
        likesCount: r.likesCount + (isLiked ? 1 : 0),
      );
    }).toList();

    return results;
  }

  // ─── Likes ────────────────────────────────────────────────

  Future<List<String>> getLikedReviewIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_keyLikedReviews) ?? [];
  }

  Future<bool> isReviewLiked(String reviewId) async {
    final ids = await getLikedReviewIds();
    return ids.contains(reviewId);
  }

  Future<bool> toggleLikeReview(String reviewId) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_keyLikedReviews) ?? [];
    bool nowLiked = false;

    if (ids.contains(reviewId)) {
      ids.remove(reviewId);
    } else {
      ids.add(reviewId);
      nowLiked = true;
    }

    await prefs.setStringList(_keyLikedReviews, ids);
    return nowLiked;
  }

  // ─── Comments on Reviews ──────────────────────────────────

  Future<List<Map<String, dynamic>>> getComments(String reviewId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyReviewComments);
    if (raw == null || raw.isEmpty) return _getMockComments(reviewId);

    try {
      final Map<String, dynamic> decoded = json.decode(raw) as Map<String, dynamic>;
      final listRaw = decoded[reviewId] as List<dynamic>? ?? [];
      final localComments = listRaw.map((e) => Map<String, dynamic>.from(e as Map)).toList();

      // Gabungkan mock comments + local comments
      final allComments = _getMockComments(reviewId)..addAll(localComments);
      return allComments;
    } catch (_) {
      return _getMockComments(reviewId);
    }
  }

  Future<void> addComment(String reviewId, String content) async {
    final user = AuthService().currentUser;
    final username = user?.email?.split('@').first ?? 'User';
    final avatarUrl = user?.userMetadata?['avatar_url'] as String?;

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyReviewComments);
    Map<String, dynamic> decoded = {};
    if (raw != null && raw.isNotEmpty) {
      try {
        decoded = json.decode(raw) as Map<String, dynamic>;
      } catch (_) {}
    }

    final listRaw = decoded[reviewId] as List<dynamic>? ?? [];
    final list = listRaw.map((e) => Map<String, dynamic>.from(e as Map)).toList();

    list.add({
      'author': username,
      'avatar': avatarUrl,
      'content': content.trim(),
      'time': 'Baru saja',
      'created_at': DateTime.now().toIso8601String(),
    });

    decoded[reviewId] = list;
    await prefs.setString(_keyReviewComments, json.encode(decoded));
  }

  List<Map<String, dynamic>> _getMockComments(String reviewId) {
    if (reviewId == 'mock_rev_1') {
      return [
        {
          'author': 'sarah_jean',
          'avatar': 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=80',
          'content': 'Sangat setuju! Adegan perkelahian di lorong gravitasi nol itu sinematik legendaris.',
          'time': '1 hari lalu',
        },
        {
          'author': 'budi_cinephile',
          'avatar': 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=80',
          'content': 'Menurutku gasingnya berhenti berputar di akhir. Ada suara retakan kecil kalau didengar pakai headphone.',
          'time': '12 jam lalu',
        }
      ];
    } else if (reviewId == 'mock_rev_2') {
      return [
        {
          'author': 'alex_cinema',
          'avatar': 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=80',
          'content': 'Soundtrack "No Time for Caution" di adegan docking kapal itu bener-bener masterpiece.',
          'time': '2 hari lalu',
        }
      ];
    }
    return [];
  }

  // ─── Friend Activities Feed ───────────────────────────────

  Future<List<Map<String, dynamic>>> getFriendActivities() async {
    // Gabungkan mock activities statis dengan data tindakan user jika ada
    final activities = <Map<String, dynamic>>[
      {
        'user': 'sarah_jean',
        'avatar': 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=80',
        'action': 'menonton',
        'movie': 'Dune: Part Two',
        'movie_id': 693134,
        'detail': '★ 4.5/5  •  "Visual yang megah!"',
        'time': '2 jam lalu',
      },
      {
        'user': 'alex_cinema',
        'avatar': 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=80',
        'action': 'menambahkan ke watchlist',
        'movie': 'Oppenheimer',
        'movie_id': 872585,
        'time': '4 jam lalu',
      },
      {
        'user': 'diana_movies',
        'avatar': 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=80',
        'action': 'mereview',
        'movie': 'Parasite',
        'movie_id': 496243,
        'detail': '★ 5.0/5  •  "Komedi hitam yang luar biasa satirnya."',
        'time': '1 hari lalu',
      },
      {
        'user': 'sutan_film',
        'avatar': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=80',
        'action': 'membuat diskusi',
        'thread': 'Rekomendasi Film Plot Twist Terbaik Abad 21',
        'time': '3 hari lalu',
      },
    ];

    return activities;
  }
}
