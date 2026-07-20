import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aftercredits/models/community_review_model.dart';
import 'package:aftercredits/core/services/movie_user_data_service.dart';
import 'package:aftercredits/core/services/auth_service.dart';
import 'package:aftercredits/core/services/user_profile_service.dart';

class ReviewCommunityService {
  static final ReviewCommunityService _instance = ReviewCommunityService._internal();
  factory ReviewCommunityService() => _instance;
  ReviewCommunityService._internal();

  String get _userIdSuffix => AuthService().currentUser?.id ?? 'guest';

  String get _keyLikedReviews => 'user_liked_reviews_$_userIdSuffix';
  String get _keyReviewComments => 'user_review_comments_$_userIdSuffix';

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
    
    // Ambil profil lengkap dari Supabase untuk username & avatar
    String username = currentUser?.email?.split('@').first ?? 'Kamu';
    String? avatarUrl;
    if (currentUser != null) {
      try {
        final profile = await UserProfileService().getProfile(currentUser.id);
        if (profile != null) {
          username = profile.username.isNotEmpty ? profile.username : username;
          avatarUrl = profile.avatarUrl;
        }
      } catch (_) {
        // Gunakan fallback jika gagal
      }
    }

    for (final entry in userReviews.entries) {
      final rev = entry.value;
      
      final now = DateTime.now();
      final diff = now.difference(rev.createdAt);
      String timeLabel;
      if (diff.inMinutes < 60) {
        timeLabel = '${diff.inMinutes <= 0 ? 1 : diff.inMinutes} menit lalu';
      } else if (diff.inHours < 24) {
        timeLabel = '${diff.inHours} jam lalu';
      } else if (diff.inDays < 7) {
        timeLabel = '${diff.inDays} hari lalu';
      } else {
        timeLabel = '${rev.createdAt.day}/${rev.createdAt.month}/${rev.createdAt.year}';
      }

      list.add(CommunityReviewModel(
        id: 'user_rev_${rev.movieId}',
        movieId: rev.movieId,
        movieTitle: 'Film #${rev.movieId}',
        authorName: username,
        authorAvatar: avatarUrl,
        rating: rev.rating,
        text: rev.text,
        likesCount: 0,
        timeLabel: timeLabel,
        isUserReview: true,
      ));
    }

    // Tambahkan status likes yang tersimpan di lokal
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
    List<Map<String, dynamic>> allComments;

    if (raw == null || raw.isEmpty) {
      allComments = _getMockComments(reviewId);
    } else {
      try {
        final Map<String, dynamic> decoded = json.decode(raw) as Map<String, dynamic>;
        final listRaw = decoded[reviewId] as List<dynamic>? ?? [];
        final localComments = listRaw.map((e) => Map<String, dynamic>.from(e as Map)).toList();

        allComments = _getMockComments(reviewId)..addAll(localComments);
      } catch (_) {
        allComments = _getMockComments(reviewId);
      }
    }

    // Jika ada komentar lokal dari user saat ini yang sebelumnya menggunakan email prefix, ganti dengan username aktual dari profil
    final user = AuthService().currentUser;
    if (user != null) {
      String? actualUsername;
      String? actualAvatar;
      try {
        final profile = await UserProfileService().getProfile(user.id);
        if (profile != null && profile.username.isNotEmpty) {
          actualUsername = profile.username;
          actualAvatar = profile.avatarUrl;
        }
      } catch (_) {}

      if (actualUsername != null) {
        final emailPrefix = user.email?.split('@').first;
        for (var c in allComments) {
          if (c['author'] == emailPrefix || c['author'] == 'User' || c['author'] == 'Kamu') {
            c['author'] = actualUsername;
            if (actualAvatar != null) c['avatar'] = actualAvatar;
          }
        }
      }
    }

    return allComments;
  }

  Future<void> addComment(String reviewId, String content) async {
    final user = AuthService().currentUser;
    String username = user?.email?.split('@').first ?? 'User';
    String? avatarUrl = user?.userMetadata?['avatar_url'] as String?;

    if (user != null) {
      try {
        final profile = await UserProfileService().getProfile(user.id);
        if (profile != null) {
          username = profile.username.isNotEmpty ? profile.username : username;
          avatarUrl = profile.avatarUrl ?? avatarUrl;
        }
      } catch (_) {}
    }

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
    // Return empty until real friend activities from Supabase are fetched
    return [];
  }
}
