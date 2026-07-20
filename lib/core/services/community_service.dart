import 'supabase_service.dart';

class CommunityService {
  static final CommunityService _instance = CommunityService._internal();
  factory CommunityService() => _instance;
  CommunityService._internal();

  /// Helper untuk memparsing hitungan count dari join query Supabase.
  int _parseCount(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is List && value.isNotEmpty) {
      final first = value.first;
      if (first is Map && first.containsKey('count')) {
        return first['count'] as int? ?? 0;
      }
    }
    if (value is Map && value.containsKey('count')) {
      return value['count'] as int? ?? 0;
    }
    return 0;
  }

  // ─── Fetch Threads ────────────────────────────────────────

  /// Mengambil list thread dengan filter kategori, search query, dan pagination.
  Future<List<Map<String, dynamic>>> getThreads({
    String? category,
    String? query,
    int page = 1,
    int limit = 10,
  }) async {
    final offset = (page - 1) * limit;

    // Mulai query
    var selectQuery = supabase.from('threads').select('''
      *,
      author:profiles(username, avatar_url),
      likes_count:thread_likes(count),
      comments_count:comments(count)
    ''');

    // Filter kategori
    if (category != null && category.isNotEmpty && category.toLowerCase() != 'semua') {
      String tag = category.toUpperCase();
      if (tag == 'SPOILER TALK') tag = 'SPOILER';
      selectQuery = selectQuery.eq('tag', tag);
    }

    // Filter search query
    if (query != null && query.isNotEmpty) {
      selectQuery = selectQuery.or('title.ilike.%$query%,preview.ilike.%$query%,movie_title.ilike.%$query%');
    }

    // Pagination & Sorting
    final response = await selectQuery
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    final List<dynamic> data = response as List<dynamic>? ?? [];

    return data.map((item) {
      final map = Map<String, dynamic>.from(item as Map);
      
      // Parse author info
      final authorData = map['author'] as Map?;
      final authorName = authorData?['username'] as String? ?? 'Anonymous';
      final avatarUrl = authorData?['avatar_url'] as String?;

      // Parse counts
      final likesCount = _parseCount(map['likes_count']);
      final commentsCount = _parseCount(map['comments_count']);

      return {
        'id': map['id'],
        'title': map['title'],
        'preview': map['preview'],
        'author': authorName,
        'author_avatar': avatarUrl,
        'author_id': map['author_id'],
        'time': _formatTimeAgo(DateTime.parse(map['created_at'] as String)),
        'created_at_raw': map['created_at'],
        'likes': likesCount,
        'comments': commentsCount,
        'views': map['views_count'] as int? ?? 0,
        'tag': map['tag'],
        'tagColor': map['tag_color'] as int? ?? 0xFFE50914,
        'movie': map['movie_title'],
        'movie_id': map['movie_id'],
        'posterUrl': map['poster_url'],
      };
    }).toList();
  }

  // ─── Fetch Single Thread ──────────────────────────────────

  Future<Map<String, dynamic>?> getThreadDetail(String threadId) async {
    final response = await supabase.from('threads').select('''
      *,
      author:profiles(username, avatar_url),
      likes_count:thread_likes(count),
      comments_count:comments(count)
    ''').eq('id', threadId).maybeSingle();

    if (response == null) return null;

    final map = Map<String, dynamic>.from(response as Map);
    final authorData = map['author'] as Map?;
    final authorName = authorData?['username'] as String? ?? 'Anonymous';
    final avatarUrl = authorData?['avatar_url'] as String?;

    return {
      'id': map['id'],
      'title': map['title'],
      'preview': map['preview'],
      'author': authorName,
      'author_avatar': avatarUrl,
      'author_id': map['author_id'],
      'time': _formatTimeAgo(DateTime.parse(map['created_at'] as String)),
      'created_at_raw': map['created_at'],
      'likes': _parseCount(map['likes_count']),
      'comments': _parseCount(map['comments_count']),
      'views': map['views_count'] as int? ?? 0,
      'tag': map['tag'],
      'tagColor': map['tag_color'] as int? ?? 0xFFE50914,
      'movie': map['movie_title'],
      'movie_id': map['movie_id'],
      'posterUrl': map['poster_url'],
    };
  }

  // ─── Create Thread ────────────────────────────────────────

  Future<Map<String, dynamic>> createThread({
    required String title,
    required String preview,
    required String tag,
    required int tagColor,
    int? movieId,
    String? movieTitle,
    String? posterUrl,
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('Silakan masuk terlebih dahulu');

    final data = await supabase.from('threads').insert({
      'title': title,
      'preview': preview,
      'tag': tag.toUpperCase(),
      'tag_color': tagColor,
      'author_id': user.id,
      'movie_id': movieId,
      'movie_title': movieTitle,
      'poster_url': posterUrl,
      'views_count': 0,
    }).select().single();

    return Map<String, dynamic>.from(data as Map);
  }

  // ─── Like / Unlike Thread ────────────────────────────────

  Future<void> toggleLike({required String threadId, required bool like}) async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('Silakan masuk terlebih dahulu');

    if (like) {
      await supabase.from('thread_likes').upsert({
        'thread_id': threadId,
        'user_id': user.id,
      });
    } else {
      await supabase
          .from('thread_likes')
          .delete()
          .eq('thread_id', threadId)
          .eq('user_id', user.id);
    }
  }

  Future<bool> isLiked(String threadId) async {
    final user = supabase.auth.currentUser;
    if (user == null) return false;

    final data = await supabase
        .from('thread_likes')
        .select()
        .eq('thread_id', threadId)
        .eq('user_id', user.id)
        .maybeSingle();

    return data != null;
  }

  // ─── Views Count ──────────────────────────────────────────

  Future<void> incrementViewCount(String threadId) async {
    try {
      // Dapatkan data thread
      final data = await supabase
          .from('threads')
          .select('views_count')
          .eq('id', threadId)
          .maybeSingle();

      if (data != null) {
        final currentViews = (data['views_count'] as int?) ?? 0;
        await supabase
            .from('threads')
            .update({'views_count': currentViews + 1})
            .eq('id', threadId);
      }
    } catch (_) {
      // Abaikan error penambahan view count
    }
  }

  // ─── Comments CRUD ────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getComments(String threadId) async {
    final response = await supabase
        .from('comments')
        .select('*, author:profiles(username, avatar_url)')
        .eq('thread_id', threadId)
        .order('created_at', ascending: true);

    final List<dynamic> data = response as List<dynamic>? ?? [];

    return data.map((item) {
      final map = Map<String, dynamic>.from(item as Map);
      final authorData = map['author'] as Map?;
      final authorName = authorData?['username'] as String? ?? 'Anonymous';
      final avatarUrl = authorData?['avatar_url'] as String?;

      return {
        'id': map['id'],
        'thread_id': map['thread_id'],
        'author_id': map['author_id'],
        'author': authorName,
        'author_avatar': avatarUrl,
        'content': map['content'],
        'time': _formatTimeAgo(DateTime.parse(map['created_at'] as String)),
        'created_at_raw': map['created_at'],
        // parent_id tersedia jika kolom sudah ada di DB (untuk cascade delete)
        'parent_id': map['parent_id'],
      };
    }).toList();
  }

  Future<void> addComment({required String threadId, required String content}) async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('Silakan masuk terlebih dahulu');

    await supabase.from('comments').insert({
      'thread_id': threadId,
      'author_id': user.id,
      'content': content.trim(),
    });
  }

  Future<void> editComment({required String commentId, required String newContent}) async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('Silakan masuk terlebih dahulu');

    await supabase
        .from('comments')
        .update({'content': newContent.trim()})
        .eq('id', commentId)
        .eq('author_id', user.id);
  }

  Future<void> deleteComment(String commentId) async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('Silakan masuk terlebih dahulu');

    // ponytail: soft-delete ala Reddit — update teks, bukan hapus row
    await supabase
        .from('comments')
        .update({'content': '[Komentar ini telah dihapus]'})
        .eq('id', commentId)
        .eq('author_id', user.id);
  }

  // ─── Threads by User ──────────────────────────────────────

  /// Mengambil semua thread yang dibuat oleh [userId].
  Future<List<Map<String, dynamic>>> getThreadsByUser(String userId) async {
    final response = await supabase.from('threads').select('''
      *,
      author:profiles(username, avatar_url),
      likes_count:thread_likes(count),
      comments_count:comments(count)
    ''').eq('author_id', userId).order('created_at', ascending: false);

    final List<dynamic> data = response as List<dynamic>? ?? [];

    return data.map((item) {
      final map = Map<String, dynamic>.from(item as Map);
      final authorData = map['author'] as Map?;
      final authorName = authorData?['username'] as String? ?? 'Anonymous';
      final avatarUrl = authorData?['avatar_url'] as String?;

      return {
        'id': map['id'],
        'title': map['title'],
        'preview': map['preview'],
        'author': authorName,
        'author_avatar': avatarUrl,
        'author_id': map['author_id'],
        'time': _formatTimeAgo(DateTime.parse(map['created_at'] as String)),
        'likes': _parseCount(map['likes_count']),
        'comments': _parseCount(map['comments_count']),
        'views': map['views_count'] as int? ?? 0,
        'tag': map['tag'],
        'tagColor': map['tag_color'] as int? ?? 0xFFE50914,
        'movie': map['movie_title'],
        'movie_id': map['movie_id'],
        'posterUrl': map['poster_url'],
      };
    }).toList();
  }

  // ─── Trending & Popular Sidebar ───────────────────────────

  /// Mengambil trending thread terpopuler.
  Future<List<Map<String, dynamic>>> getTrendingThreads() async {
    // Ambil top 5 thread berdasarkan likes + views
    final response = await supabase.from('threads').select('''
      *,
      author:profiles(username, avatar_url),
      likes_count:thread_likes(count),
      comments_count:comments(count)
    ''').order('views_count', ascending: false).limit(5);

    final List<dynamic> data = response as List<dynamic>? ?? [];

    return data.map((item) {
      final map = Map<String, dynamic>.from(item as Map);
      final authorData = map['author'] as Map?;
      final authorName = authorData?['username'] as String? ?? 'Anonymous';

      return {
        'id': map['id'],
        'title': map['title'],
        'author': authorName,
        'time': _formatTimeAgo(DateTime.parse(map['created_at'] as String)),
        'likes': _parseCount(map['likes_count']),
        'comments': _parseCount(map['comments_count']),
        'views': map['views_count'] as int? ?? 0,
        'tag': map['tag'],
        'tagColor': map['tag_color'] as int? ?? 0xFFE50914,
        'posterUrl': map['poster_url'],
      };
    }).toList();
  }

  // ─── Search Users ─────────────────────────────────────────

  /// Mencari user berdasarkan username. Max 5 hasil.
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    if (query.trim().isEmpty) return [];
    final data = await supabase
        .from('profiles')
        .select('id, username, avatar_url')
        .ilike('username', '%${query.trim()}%')
        .limit(5);
    return (data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  // ─── Helper Time Ago ──────────────────────────────────────

  String _formatTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inDays >= 30) {
      final months = (difference.inDays / 30).floor();
      return '$months bulan lalu';
    } else if (difference.inDays >= 7) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks minggu lalu';
    } else if (difference.inDays >= 1) {
      return '${difference.inDays} hari lalu';
    } else if (difference.inHours >= 1) {
      return '${difference.inHours} jam lalu';
    } else if (difference.inMinutes >= 1) {
      return '${difference.inMinutes} menit lalu';
    } else {
      return 'Baru saja';
    }
  }
}
