import 'package:aftercredits/core/services/supabase_service.dart';

/// Service untuk operasi follow/unfollow antar pengguna.
/// Menggunakan tabel `follows` di Supabase dengan struktur:
///   follower_id UUID, following_id UUID, created_at TIMESTAMPTZ
class FollowService {
  static final FollowService _instance = FollowService._internal();
  factory FollowService() => _instance;
  FollowService._internal();

  // ─── Follow / Unfollow ────────────────────────────────────

  /// Follow pengguna dengan [targetUserId].
  Future<void> followUser(String targetUserId) async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('Silakan masuk terlebih dahulu');
    if (user.id == targetUserId) throw Exception('Tidak bisa follow diri sendiri');

    await supabase.from('follows').upsert({
      'follower_id': user.id,
      'following_id': targetUserId,
    });
  }

  /// Unfollow pengguna dengan [targetUserId].
  Future<void> unfollowUser(String targetUserId) async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('Silakan masuk terlebih dahulu');

    await supabase
        .from('follows')
        .delete()
        .eq('follower_id', user.id)
        .eq('following_id', targetUserId);
  }

  // ─── Status Check ─────────────────────────────────────────

  /// Kembalikan true jika current user sedang follow [targetUserId].
  Future<bool> isFollowing(String targetUserId) async {
    final user = supabase.auth.currentUser;
    if (user == null) return false;

    final data = await supabase
        .from('follows')
        .select()
        .eq('follower_id', user.id)
        .eq('following_id', targetUserId)
        .maybeSingle();

    return data != null;
  }

  // ─── Counts ───────────────────────────────────────────────

  /// Kembalikan jumlah followers dan following untuk [userId].
  Future<({int followers, int following})> getFollowCounts(String userId) async {
    try {
      final results = await Future.wait([
        supabase
            .from('follows')
            .select()
            .eq('following_id', userId),
        supabase
            .from('follows')
            .select()
            .eq('follower_id', userId),
      ]);

      final followersList = results[0] as List<dynamic>;
      final followingList = results[1] as List<dynamic>;

      return (followers: followersList.length, following: followingList.length);
    } catch (_) {
      return (followers: 0, following: 0);
    }
  }
}
