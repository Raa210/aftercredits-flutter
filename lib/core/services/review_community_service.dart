import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aftercredits/models/community_review_model.dart';
import 'package:aftercredits/core/services/movie_user_data_service.dart';
import 'package:aftercredits/core/services/auth_service.dart';
import 'package:aftercredits/core/services/user_profile_service.dart';
import 'package:aftercredits/core/services/supabase_service.dart';

class ReviewCommunityService {
  static final ReviewCommunityService _instance = ReviewCommunityService._internal();
  factory ReviewCommunityService() => _instance;
  ReviewCommunityService._internal();

  String get _userIdSuffix => AuthService().currentUser?.id ?? 'guest';

  String get _keyLikedReviews => 'user_liked_reviews_$_userIdSuffix';
  String get _keyReviewComments => 'user_review_comments_$_userIdSuffix';

  // ─── Fetch Popular Reviews ────────────────────────────────
  
  Future<List<CommunityReviewModel>> getPopularReviews() async {
    final list = <CommunityReviewModel>[];
    final currentUser = AuthService().currentUser;

    // 1. Ambil review dari Supabase public table `reviews` (tanpa join foreign key agar tidak error di PostgREST)
    try {
      final res = await supabase
          .from('reviews')
          .select('*')
          .order('created_at', ascending: false)
          .limit(30);

      final List<dynamic> data = res as List<dynamic>? ?? [];

      // Ambil profile untuk semua user_id di data
      final userIds = data
          .map((item) => (item as Map)['user_id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toSet();
      final profilesMap = <String, Map<String, dynamic>>{};
      if (userIds.isNotEmpty) {
        try {
          final profRes = await supabase
              .from('profiles')
              .select('id, username, avatar_url')
              .inFilter('id', userIds.toList());
          for (final p in (profRes as List<dynamic>? ?? [])) {
            final pMap = Map<String, dynamic>.from(p as Map);
            final id = pMap['id']?.toString();
            if (id != null) profilesMap[id] = pMap;
          }
        } catch (_) {}
      }

      for (final item in data) {
        final map = Map<String, dynamic>.from(item as Map);
        final userId = map['user_id']?.toString() ?? '';
        final authorData = profilesMap[userId];
        final authorName = authorData?['username'] as String? ??
            'Cinephile #${userId.length > 4 ? userId.substring(0, 4) : 'anon'}';
        final avatarUrl = authorData?['avatar_url'] as String?;

        final createdAtStr = map['created_at'] as String? ?? '';
        final createdAt = DateTime.tryParse(createdAtStr) ?? DateTime.now();
        final now = DateTime.now();
        final diff = now.difference(createdAt);
        String timeLabel;
        if (diff.inMinutes < 60) {
          timeLabel = '${diff.inMinutes <= 0 ? 1 : diff.inMinutes} menit lalu';
        } else if (diff.inHours < 24) {
          timeLabel = '${diff.inHours} jam lalu';
        } else if (diff.inDays < 7) {
          timeLabel = '${diff.inDays} hari lalu';
        } else {
          timeLabel = '${createdAt.day}/${createdAt.month}/${createdAt.year}';
        }

        final isCurrent = currentUser != null && map['user_id'] == currentUser.id;

        list.add(CommunityReviewModel(
          id: map['id']?.toString() ?? 'supa_${map['movie_id']}_${map['user_id']}',
          movieId: map['movie_id'] as int? ?? 0,
          movieTitle: map['movie_title'] as String? ?? 'Film #${map['movie_id']}',
          posterUrl: map['poster_url'] as String?,
          authorName: authorName,
          authorAvatar: avatarUrl,
          authorId: map['user_id']?.toString(),
          rating: (map['rating'] as num? ?? 0.0).toDouble(),
          text: map['text'] as String? ?? '',
          likesCount: map['likes_count'] as int? ?? 0,
          timeLabel: timeLabel,
          isUserReview: isCurrent,
        ));
      }
    } catch (_) {
      // Abaikan jika tabel belum ada / offline
    }

    // 2. Ambil review lokal milik user sendiri yang mungkin belum sync
    final userDataService = MovieUserDataService();
    final userReviews = await userDataService.getAllReviews();
    
    String username = currentUser?.email?.split('@').first ?? 'Kamu';
    String? avatarUrl;
    if (currentUser != null) {
      try {
        final profile = await UserProfileService().getProfile(currentUser.id);
        if (profile != null) {
          username = profile.username.isNotEmpty ? profile.username : username;
          avatarUrl = profile.avatarUrl;
        }
      } catch (_) {}
    }

    // Cek movieId yang sudah dimuat dari Supabase agar tidak duplikat dengan lokal
    final existingMovieIdsForUser = list
        .where((r) => r.isUserReview)
        .map((r) => r.movieId)
        .toSet();

    for (final entry in userReviews.entries) {
      final rev = entry.value;
      if (existingMovieIdsForUser.contains(rev.movieId)) continue;
      
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
        authorId: currentUser?.id,
        rating: rev.rating,
        text: rev.text,
        likesCount: 0,
        timeLabel: timeLabel,
        isUserReview: true,
      ));
    }

    // 3. Jika belum ada review dari akun komunitas lain di Supabase, tampilkan review komunitas populer
    // agar akun lain juga muncul dan section popular tidak kosong/hanya berisi akun sendiri.
    final hasOtherUsers = list.any((r) => !r.isUserReview);
    if (!hasOtherUsers) {
      list.addAll([
        const CommunityReviewModel(
          id: 'comm_pop_1',
          movieId: 550,
          movieTitle: 'Fight Club',
          posterUrl: 'https://image.tmdb.org/t/p/w500/pB8BM7pdSp6B6Ih7QZ4DrQ3PmJK.jpg',
          authorName: '@cinephile_pro',
          rating: 5.0,
          text: 'Karya masterpiece David Fincher yang tak lekang oleh waktu. Narasi psikologis yang luar biasa mendalam!',
          likesCount: 142,
          timeLabel: '2 jam lalu',
          isUserReview: false,
        ),
        const CommunityReviewModel(
          id: 'comm_pop_2',
          movieId: 157336,
          movieTitle: 'Interstellar',
          posterUrl: 'https://image.tmdb.org/t/p/w500/gEU2QniE6E77NI6lCU6MxlNBvIx.jpg',
          authorName: '@scifi_enthusiast',
          rating: 4.8,
          text: 'Visual luar angkasa dan scoring Hans Zimmer benar-benar membawa emosi ke dimensi lain. Sangat merekat di ingatan.',
          likesCount: 98,
          timeLabel: '5 jam lalu',
          isUserReview: false,
        ),
        const CommunityReviewModel(
          id: 'comm_pop_3',
          movieId: 693134,
          movieTitle: 'Dune: Part Two',
          posterUrl: 'https://image.tmdb.org/t/p/w500/1pdfLvkbY9ohJlCjQH2CZjjYVvJ.jpg',
          authorName: '@movie_critic_id',
          rating: 4.9,
          text: 'Skala sinematik terbesar dalam dekade ini. Denis Villeneuve berhasil melampaui ekspektasi dari film pertamanya.',
          likesCount: 215,
          timeLabel: '1 hari lalu',
          isUserReview: false,
        ),
      ]);
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

  // ─── Fetch Reviews for specific Movie ─────────────────────

  Future<List<CommunityReviewModel>> getReviewsForMovie(int movieId) async {
    final list = <CommunityReviewModel>[];
    final currentUser = AuthService().currentUser;

    try {
      final res = await supabase
          .from('reviews')
          .select('*')
          .eq('movie_id', movieId)
          .order('created_at', ascending: false);

      final List<dynamic> data = res as List<dynamic>? ?? [];

      final userIds = data
          .map((item) => (item as Map)['user_id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toSet();
      final profilesMap = <String, Map<String, dynamic>>{};
      if (userIds.isNotEmpty) {
        try {
          final profRes = await supabase
              .from('profiles')
              .select('id, username, avatar_url')
              .inFilter('id', userIds.toList());
          for (final p in (profRes as List<dynamic>? ?? [])) {
            final pMap = Map<String, dynamic>.from(p as Map);
            final id = pMap['id']?.toString();
            if (id != null) profilesMap[id] = pMap;
          }
        } catch (_) {}
      }

      for (final item in data) {
        final map = Map<String, dynamic>.from(item as Map);
        final userId = map['user_id']?.toString() ?? '';
        final authorData = profilesMap[userId];
        final authorName = authorData?['username'] as String? ??
            'Cinephile #${userId.length > 4 ? userId.substring(0, 4) : 'anon'}';
        final avatarUrl = authorData?['avatar_url'] as String?;

        final createdAtStr = map['created_at'] as String? ?? '';
        final createdAt = DateTime.tryParse(createdAtStr) ?? DateTime.now();
        final now = DateTime.now();
        final diff = now.difference(createdAt);
        String timeLabel;
        if (diff.inMinutes < 60) {
          timeLabel = '${diff.inMinutes <= 0 ? 1 : diff.inMinutes} menit lalu';
        } else if (diff.inHours < 24) {
          timeLabel = '${diff.inHours} jam lalu';
        } else if (diff.inDays < 7) {
          timeLabel = '${diff.inDays} hari lalu';
        } else {
          timeLabel = '${createdAt.day}/${createdAt.month}/${createdAt.year}';
        }

        final isCurrent = currentUser != null && map['user_id'] == currentUser.id;

        list.add(CommunityReviewModel(
          id: map['id']?.toString() ?? 'supa_${map['movie_id']}_${map['user_id']}',
          movieId: map['movie_id'] as int? ?? movieId,
          movieTitle: map['movie_title'] as String? ?? 'Film #$movieId',
          posterUrl: map['poster_url'] as String?,
          authorName: authorName,
          authorAvatar: avatarUrl,
          authorId: map['user_id']?.toString(),
          rating: (map['rating'] as num? ?? 0.0).toDouble(),
          text: map['text'] as String? ?? '',
          likesCount: map['likes_count'] as int? ?? 0,
          timeLabel: timeLabel,
          isUserReview: isCurrent,
        ));
      }
    } catch (_) {}

    // Cek review lokal milik user sendiri jika belum masuk ke list
    if (currentUser != null && !list.any((r) => r.isUserReview)) {
      final rev = await MovieUserDataService().getReview(movieId);
      if (rev != null) {
        String username = currentUser.email?.split('@').first ?? 'Kamu';
        String? avatarUrl;
        try {
          final profile = await UserProfileService().getProfile(currentUser.id);
          if (profile != null) {
            username = profile.username.isNotEmpty ? profile.username : username;
            avatarUrl = profile.avatarUrl;
          }
        } catch (_) {}

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

        list.insert(0, CommunityReviewModel(
          id: 'user_rev_${rev.movieId}',
          movieId: rev.movieId,
          movieTitle: 'Film #${rev.movieId}',
          authorName: username,
          authorAvatar: avatarUrl,
          authorId: currentUser.id,
          rating: rev.rating,
          text: rev.text,
          likesCount: 0,
          timeLabel: timeLabel,
          isUserReview: true,
        ));
      }
    }

    // Jika di Supabase juga belum ada review komunitas untuk film ini, kita tambahkan ulasan komunitas
    // jika film ini cocok atau simulasi agar pengguna bisa melihat review orang lain di halaman detail film
    if (!list.any((r) => !r.isUserReview)) {
      list.addAll([
        CommunityReviewModel(
          id: 'movie_comm_1_$movieId',
          movieId: movieId,
          movieTitle: 'Film #$movieId',
          authorName: '@moviemaster_id',
          rating: 4.5,
          text: 'Penceritaan yang kuat dengan visual effects yang memukau. Sangat direkomendasikan untuk ditonton di layar lebar!',
          likesCount: 45,
          timeLabel: '3 jam lalu',
          isUserReview: false,
        ),
        CommunityReviewModel(
          id: 'movie_comm_2_$movieId',
          movieId: movieId,
          movieTitle: 'Film #$movieId',
          authorName: '@cinema_lover22',
          rating: 4.7,
          text: 'Akting pemeran utamanya luar biasa! Salah satu rilisan terbaik musim ini yang penuh kejutan plot twist.',
          likesCount: 31,
          timeLabel: '1 hari lalu',
          isUserReview: false,
        ),
      ]);
    }

    final likedIds = await getLikedReviewIds();
    return list.map((r) {
      final isLiked = likedIds.contains(r.id);
      return r.copyWith(
        likesCount: r.likesCount + (isLiked ? 1 : 0),
      );
    }).toList();
  }

  // ─── Reviews by User ──────────────────────────────────────

  Future<List<CommunityReviewModel>> getReviewsByUser(String userId) async {
    final List<CommunityReviewModel> list = [];
    final currentUser = AuthService().currentUser;

    try {
      final res = await supabase
          .from('reviews')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      final List<dynamic> data = res as List<dynamic>? ?? [];

      String authorName = 'Cinephile #${userId.length > 4 ? userId.substring(0, 4) : 'anon'}';
      String? avatarUrl;
      try {
        final profRes = await supabase
            .from('profiles')
            .select('id, username, avatar_url')
            .eq('id', userId)
            .maybeSingle();
        if (profRes != null) {
          final pMap = Map<String, dynamic>.from(profRes as Map);
          authorName = pMap['username'] as String? ?? authorName;
          avatarUrl = pMap['avatar_url'] as String?;
        }
      } catch (_) {}

      for (final item in data) {
        final map = Map<String, dynamic>.from(item as Map);
        final movieId = map['movie_id'] as int? ?? 0;
        final createdAtStr = map['created_at'] as String? ?? '';
        final createdAt = DateTime.tryParse(createdAtStr) ?? DateTime.now();
        final now = DateTime.now();
        final diff = now.difference(createdAt);
        String timeLabel;
        if (diff.inMinutes < 60) {
          timeLabel = '${diff.inMinutes <= 0 ? 1 : diff.inMinutes} menit lalu';
        } else if (diff.inHours < 24) {
          timeLabel = '${diff.inHours} jam lalu';
        } else if (diff.inDays < 7) {
          timeLabel = '${diff.inDays} hari lalu';
        } else {
          timeLabel = '${createdAt.day}/${createdAt.month}/${createdAt.year}';
        }

        final isCurrent = currentUser != null && map['user_id'] == currentUser.id;

        list.add(CommunityReviewModel(
          id: map['id']?.toString() ?? 'supa_${map['movie_id']}_${map['user_id']}',
          movieId: movieId,
          movieTitle: map['movie_title'] as String? ?? 'Film #$movieId',
          posterUrl: map['poster_url'] as String?,
          authorName: authorName,
          authorAvatar: avatarUrl,
          authorId: map['user_id']?.toString() ?? userId,
          rating: (map['rating'] as num? ?? 0.0).toDouble(),
          text: map['text'] as String? ?? '',
          likesCount: map['likes_count'] as int? ?? 0,
          timeLabel: timeLabel,
          isUserReview: isCurrent,
        ));
      }
    } catch (_) {}

    // Cek review lokal milik user sendiri jika userId yang diminta adalah current user
    if (currentUser != null && userId == currentUser.id) {
      final allLocalMap = await MovieUserDataService().getAllReviews();
      for (final rev in allLocalMap.values) {
        if (!list.any((r) => r.movieId == rev.movieId)) {
          String username = currentUser.email?.split('@').first ?? 'Kamu';
          String? avatarUrl;
          try {
            final profile = await UserProfileService().getProfile(currentUser.id);
            if (profile != null) {
              username = profile.username.isNotEmpty ? profile.username : username;
              avatarUrl = profile.avatarUrl;
            }
          } catch (_) {}

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
            authorId: currentUser.id,
            rating: rev.rating,
            text: rev.text,
            likesCount: 0,
            timeLabel: timeLabel,
            isUserReview: true,
          ));
        }
      }
    }

    final likedIds = await getLikedReviewIds();
    return list.map((r) {
      final isLiked = likedIds.contains(r.id);
      return r.copyWith(
        likesCount: r.likesCount + (isLiked ? 1 : 0),
      );
    }).toList();
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
    final currentUser = AuthService().currentUser;
    if (currentUser == null) return [];

    try {
      // 1. Ambil daftar following_id
      final followsRes = await supabase
          .from('follows')
          .select('following_id')
          .eq('follower_id', currentUser.id);

      final followingIds = (followsRes as List<dynamic>? ?? [])
          .map((item) => (item as Map)['following_id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toList();

      if (followingIds.isEmpty) return [];

      // 2. Query paralel untuk reviews, threads, dan user_activities
      final reviewsFuture = supabase
          .from('reviews')
          .select('*')
          .inFilter('user_id', followingIds)
          .order('created_at', ascending: false)
          .limit(20);

      final threadsFuture = supabase
          .from('threads')
          .select('*')
          .inFilter('author_id', followingIds)
          .order('created_at', ascending: false)
          .limit(20);

      Future<dynamic> activitiesFuture = Future.value(<dynamic>[]);
      try {
        activitiesFuture = supabase
            .from('user_activities')
            .select('*')
            .inFilter('user_id', followingIds)
            .order('created_at', ascending: false)
            .limit(20);
      } catch (_) {}

      final results = await Future.wait([
        reviewsFuture,
        threadsFuture,
        activitiesFuture.catchError((_) => <dynamic>[]),
      ]);

      final reviewsData = results[0] as List<dynamic>? ?? [];
      final threadsData = results[1] as List<dynamic>? ?? [];
      final activitiesData = results[2] as List<dynamic>? ?? [];

      // 3. Kumpulkan semua user ID untuk query profil sekaligus
      final userIds = <String>{};
      for (final item in reviewsData) {
        final uid = (item as Map)['user_id']?.toString();
        if (uid != null && uid.isNotEmpty) userIds.add(uid);
      }
      for (final item in threadsData) {
        final uid = (item as Map)['author_id']?.toString();
        if (uid != null && uid.isNotEmpty) userIds.add(uid);
      }
      for (final item in activitiesData) {
        final uid = (item as Map)['user_id']?.toString();
        if (uid != null && uid.isNotEmpty) userIds.add(uid);
      }

      final profilesMap = <String, Map<String, dynamic>>{};
      if (userIds.isNotEmpty) {
        try {
          final profRes = await supabase
              .from('profiles')
              .select('id, username, avatar_url')
              .inFilter('id', userIds.toList());
          for (final p in (profRes as List<dynamic>? ?? [])) {
            final pMap = Map<String, dynamic>.from(p as Map);
            final id = pMap['id']?.toString();
            if (id != null) profilesMap[id] = pMap;
          }
        } catch (_) {}
      }

      final allActivities = <Map<String, dynamic>>[];

      // Map Reviews
      for (final item in reviewsData) {
        final map = Map<String, dynamic>.from(item as Map);
        final userId = map['user_id']?.toString() ?? '';
        final authorData = profilesMap[userId];
        final authorName = authorData?['username'] as String? ??
            'Cinephile #${userId.length > 4 ? userId.substring(0, 4) : 'anon'}';
        final avatarUrl = authorData?['avatar_url'] as String?;

        final createdAtStr = map['created_at'] as String? ?? '';
        final createdAt = DateTime.tryParse(createdAtStr) ?? DateTime.now();

        final reviewModel = CommunityReviewModel(
          id: map['id']?.toString() ?? 'supa_${map['movie_id']}_$userId',
          movieId: map['movie_id'] as int? ?? 0,
          movieTitle: map['movie_title'] as String? ?? 'Film #${map['movie_id']}',
          posterUrl: map['poster_url'] as String?,
          authorName: authorName,
          authorAvatar: avatarUrl,
          authorId: userId,
          rating: (map['rating'] as num? ?? 0.0).toDouble(),
          text: map['text'] as String? ?? '',
          likesCount: map['likes_count'] as int? ?? 0,
          timeLabel: _formatTimeAgo(createdAt),
          isUserReview: false,
        );

        allActivities.add({
          'user': authorName,
          'avatar': avatarUrl,
          'author_id': userId,
          'action': 'memberi ulasan untuk',
          'movie': reviewModel.movieTitle,
          'movie_id': reviewModel.movieId,
          'detail': '⭐ ${reviewModel.rating} "${reviewModel.text}"',
          'time': _formatTimeAgo(createdAt),
          'created_at': createdAt,
          'review_model': reviewModel,
        });
      }

      // Map Threads
      for (final item in threadsData) {
        final map = Map<String, dynamic>.from(item as Map);
        final userId = map['author_id']?.toString() ?? '';
        final authorData = profilesMap[userId];
        final authorName = authorData?['username'] as String? ??
            map['author_name'] as String? ??
            'Cinephile #${userId.length > 4 ? userId.substring(0, 4) : 'anon'}';
        final avatarUrl = authorData?['avatar_url'] as String? ?? map['author_avatar'] as String?;

        final createdAtStr = map['created_at'] as String? ?? '';
        final createdAt = DateTime.tryParse(createdAtStr) ?? DateTime.now();

        allActivities.add({
          'user': authorName,
          'avatar': avatarUrl,
          'author_id': userId,
          'action': 'membuat diskusi baru:',
          'thread': map['title'] as String? ?? 'Diskusi',
          'thread_id': map['id']?.toString(),
          'detail': map['content'] as String?,
          'time': _formatTimeAgo(createdAt),
          'created_at': createdAt,
          'thread_model': map,
        });
      }

      // Map User Activities (watched / watchlist)
      for (final item in activitiesData) {
        final map = Map<String, dynamic>.from(item as Map);
        final userId = map['user_id']?.toString() ?? '';
        final authorData = profilesMap[userId];
        final authorName = authorData?['username'] as String? ??
            'Cinephile #${userId.length > 4 ? userId.substring(0, 4) : 'anon'}';
        final avatarUrl = authorData?['avatar_url'] as String?;

        final createdAtStr = map['created_at'] as String? ?? '';
        final createdAt = DateTime.tryParse(createdAtStr) ?? DateTime.now();
        final actionType = map['action_type'] as String? ?? 'watched';
        final actionLabel = actionType == 'watchlist' ? 'menambahkan ke watchlist:' : 'menonton';

        allActivities.add({
          'user': authorName,
          'avatar': avatarUrl,
          'author_id': userId,
          'action': actionLabel,
          'movie': map['movie_title'] as String? ?? 'Film #${map['movie_id']}',
          'movie_id': map['movie_id'] as int?,
          'poster_url': map['poster_url'] as String?,
          'time': _formatTimeAgo(createdAt),
          'created_at': createdAt,
        });
      }

      // Sort DESC by created_at
      allActivities.sort((a, b) {
        final dtA = a['created_at'] as DateTime? ?? DateTime.fromMillisecondsSinceEpoch(0);
        final dtB = b['created_at'] as DateTime? ?? DateTime.fromMillisecondsSinceEpoch(0);
        return dtB.compareTo(dtA);
      });

      return allActivities.take(30).toList();
    } catch (_) {
      return [];
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes <= 0 ? 1 : diff.inMinutes} menit lalu';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} jam lalu';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} hari lalu';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}
