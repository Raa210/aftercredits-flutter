import 'package:flutter/material.dart';
import 'package:aftercredits/core/services/community_service.dart';
import 'package:aftercredits/core/services/auth_service.dart';
import 'package:aftercredits/core/theme/app_theme.dart';
import 'community_colors.dart';

class ThreadDetailScreen extends StatefulWidget {
  final Map<String, dynamic> thread;

  const ThreadDetailScreen({super.key, required this.thread});

  @override
  State<ThreadDetailScreen> createState() => _ThreadDetailScreenState();
}

class _ThreadDetailScreenState extends State<ThreadDetailScreen> {
  late Map<String, dynamic> _threadData;
  List<Map<String, dynamic>> _comments = [];
  bool _loadingComments = true;
  bool _liked = false;
  bool _liking = false;
  int _likesCount = 0;
  final _commentController = TextEditingController();
  final _commentFocusNode = FocusNode();
  bool _submittingComment = false;

  @override
  void initState() {
    super.initState();
    _threadData = Map<String, dynamic>.from(widget.thread);
    _likesCount = _threadData['likes'] as int? ?? 0;
    _loadData();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    // Jalankan increment view secara async di background
    CommunityService().incrementViewCount(_threadData['id'] as String);

    // Ambil detail thread terbaru, like status, dan komentar
    await Future.wait([
      _checkLikeStatus(),
      _fetchComments(),
      _refreshThreadDetails(),
    ]);
  }

  Future<void> _refreshThreadDetails() async {
    try {
      final fresh = await CommunityService().getThreadDetail(_threadData['id'] as String);
      if (fresh != null && mounted) {
        setState(() {
          _threadData = fresh;
          _likesCount = fresh['likes'] as int? ?? 0;
        });
      }
    } catch (_) {}
  }

  Future<void> _checkLikeStatus() async {
    try {
      final isLiked = await CommunityService().isLiked(_threadData['id'] as String);
      if (mounted) {
        setState(() => _liked = isLiked);
      }
    } catch (_) {}
  }

  Future<void> _fetchComments() async {
    if (mounted) setState(() => _loadingComments = true);
    try {
      final comments = await CommunityService().getComments(_threadData['id'] as String);
      if (mounted) {
        setState(() {
          _comments = comments;
          _loadingComments = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingComments = false);
    }
  }

  Future<void> _toggleLike() async {
    if (_liking) return;
    setState(() => _liking = true);

    final targetLike = !_liked;
    setState(() {
      _liked = targetLike;
      _likesCount = targetLike ? _likesCount + 1 : _likesCount - 1;
    });

    try {
      await CommunityService().toggleLike(
        threadId: _threadData['id'] as String,
        like: targetLike,
      );
    } catch (e) {
      // Revert if error
      setState(() {
        _liked = !targetLike;
        _likesCount = !targetLike ? _likesCount + 1 : _likesCount - 1;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: CommunityColors.primary,
          ),
        );
      }
    } finally {
      setState(() => _liking = false);
    }
  }

  Future<void> _addComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    setState(() => _submittingComment = true);
    try {
      await CommunityService().addComment(
        threadId: _threadData['id'] as String,
        content: text,
      );
      _commentController.clear();
      FocusScope.of(context).unfocus();
      await _fetchComments();
      _refreshThreadDetails();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: CommunityColors.primary,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submittingComment = false);
    }
  }

  Future<void> _deleteComment(String commentId) async {
    try {
      await CommunityService().deleteComment(commentId);
      await _fetchComments();
      _refreshThreadDetails();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: CommunityColors.primary,
          ),
        );
      }
    }
  }

  Future<void> _editComment(String commentId, String currentContent) async {
    final controller = TextEditingController(text: currentContent);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: CommunityColors.card,
        title: const Text(
          'Edit Komentar',
          style: TextStyle(color: CommunityColors.textPrimary),
        ),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: CommunityColors.textPrimary),
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Edit pesan komentar Anda...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal', style: TextStyle(color: CommunityColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Simpan', style: TextStyle(color: CommunityColors.primary)),
          ),
        ],
      ),
    );

    if (confirmed == true && controller.text.trim().isNotEmpty) {
      try {
        await CommunityService().editComment(
          commentId: commentId,
          newContent: controller.text.trim(),
        );
        await _fetchComments();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceAll('Exception: ', '')),
              backgroundColor: CommunityColors.primary,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final posterUrl = _threadData['posterUrl'] as String?;
    final tagColor = Color(_threadData['tagColor'] as int? ?? 0xFFE50914);
    final tag = _threadData['tag'] as String;

    return Scaffold(
      backgroundColor: CommunityColors.background,
      appBar: AppBar(
        backgroundColor: CommunityColors.background,
        title: Text(
          tag,
          style: TextStyle(
            color: tagColor,
            fontWeight: FontWeight.w900,
            fontSize: 16,
            letterSpacing: 1.0,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ─── Main Content Area (Scrollable) ────────────────
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadData,
              color: CommunityColors.primary,
              backgroundColor: CommunityColors.card,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Info Row (Author + Time)
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: CommunityColors.divider,
                          backgroundImage: _threadData['author_avatar'] != null
                              ? NetworkImage(_threadData['author_avatar'] as String)
                              : null,
                          child: _threadData['author_avatar'] == null
                              ? const Icon(Icons.person_rounded,
                                  color: CommunityColors.textSecondary, size: 20)
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '@${_threadData['author']}',
                              style: const TextStyle(
                                color: CommunityColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              _threadData['time'] as String,
                              style: const TextStyle(
                                color: CommunityColors.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),

                        // Views
                        Row(
                          children: [
                            const Icon(Icons.visibility_rounded,
                                size: 14, color: CommunityColors.textMuted),
                            const SizedBox(width: 4),
                            Text(
                              '${_threadData['views']}',
                              style: const TextStyle(
                                color: CommunityColors.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Title
                    Text(
                      _threadData['title'] as String,
                      style: const TextStyle(
                        color: CommunityColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Poster reference if any
                    if (posterUrl != null && posterUrl.isNotEmpty) ...[
                      Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(CommunityRadius.md),
                          child: Image.network(
                            posterUrl,
                            height: 250,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Preview Content Text
                    Text(
                      _threadData['preview'] as String,
                      style: const TextStyle(
                        color: CommunityColors.textPrimary,
                        fontSize: 15,
                        height: 1.6,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Actions Row (Likes)
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: CommunityColors.card,
                            borderRadius: BorderRadius.circular(CommunityRadius.pill),
                            border: Border.all(
                              color: CommunityColors.divider,
                              width: 0.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              InkWell(
                                onTap: () {
                                  if (!_liked) _toggleLike();
                                },
                                borderRadius: const BorderRadius.horizontal(left: Radius.circular(CommunityRadius.pill)),
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                                  child: Icon(
                                    Icons.arrow_upward_rounded,
                                    size: 18,
                                    color: _liked ? CommunityColors.primary : CommunityColors.textSecondary,
                                  ),
                                ),
                              ),
                              Text(
                                '$_likesCount',
                                style: TextStyle(
                                  color: _liked ? CommunityColors.primary : CommunityColors.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              InkWell(
                                onTap: () {
                                  if (_liked) _toggleLike();
                                },
                                borderRadius: const BorderRadius.horizontal(right: Radius.circular(CommunityRadius.pill)),
                                child: const Padding(
                                  padding: EdgeInsets.fromLTRB(8, 8, 16, 8),
                                  child: Icon(
                                    Icons.arrow_downward_rounded,
                                    size: 18,
                                    color: CommunityColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                    const Divider(color: CommunityColors.divider, thickness: 1),
                    const SizedBox(height: 16),

                    // Comments Section Title
                    const Text(
                      'Komentar',
                      style: TextStyle(
                        color: CommunityColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Comments List
                    if (_loadingComments)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(CommunityColors.primary),
                          ),
                        ),
                      )
                    else if (_comments.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Center(
                          child: Text(
                            'Belum ada komentar. Jadilah yang pertama!',
                            style: TextStyle(
                              color: CommunityColors.textMuted,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _comments.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final c = _comments[index];
                          final isOwnComment = c['author_id'] == AuthService().currentUser?.id;

                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: CommunityColors.card,
                              borderRadius: BorderRadius.circular(CommunityRadius.md),
                              border: Border.all(
                                color: CommunityColors.divider.withOpacity(0.5),
                                width: 0.5,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 12,
                                      backgroundColor: CommunityColors.divider,
                                      backgroundImage: c['author_avatar'] != null
                                          ? NetworkImage(c['author_avatar'] as String)
                                          : null,
                                      child: c['author_avatar'] == null
                                          ? const Icon(Icons.person_rounded,
                                              color: CommunityColors.textSecondary, size: 12)
                                          : null,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '@${c['author']}',
                                      style: const TextStyle(
                                        color: CommunityColors.textPrimary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const Spacer(),
                                    InkWell(
                                      onTap: () {
                                        _commentController.text = '@${c['author']} ';
                                        _commentFocusNode.requestFocus();
                                      },
                                      child: const Text(
                                        'Reply',
                                        style: TextStyle(
                                          color: CommunityColors.primary,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      c['time'] as String,
                                      style: const TextStyle(
                                        color: CommunityColors.textMuted,
                                        fontSize: 11,
                                      ),
                                    ),

                                    if (isOwnComment) ...[
                                      const SizedBox(width: 8),
                                      PopupMenuButton<String>(
                                        icon: const Icon(Icons.more_vert_rounded,
                                            size: 14, color: CommunityColors.textMuted),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        color: CommunityColors.card,
                                        onSelected: (val) {
                                          if (val == 'edit') {
                                            _editComment(c['id'] as String, c['content'] as String);
                                          } else if (val == 'delete') {
                                            _deleteComment(c['id'] as String);
                                          }
                                        },
                                        itemBuilder: (context) => [
                                          const PopupMenuItem(
                                            value: 'edit',
                                            child: Text('Edit', style: TextStyle(color: Colors.white, fontSize: 13)),
                                          ),
                                          const PopupMenuItem(
                                            value: 'delete',
                                            child: Text('Hapus', style: TextStyle(color: Colors.red, fontSize: 13)),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  c['content'] as String,
                                  style: const TextStyle(
                                    color: CommunityColors.textSecondary,
                                    fontSize: 13,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),

          // ─── Floating Comment Input Bar (Sticky Bottom) ────
          Container(
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            decoration: const BoxDecoration(
              color: CommunityColors.card,
              border: Border(
                top: BorderSide(color: CommunityColors.divider, width: 0.5),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: CommunityColors.background,
                      borderRadius: BorderRadius.circular(CommunityRadius.pill),
                      border: Border.all(color: CommunityColors.divider, width: 0.5),
                    ),
                    child: TextField(
                      controller: _commentController,
                      focusNode: _commentFocusNode,
                      style: const TextStyle(color: CommunityColors.textPrimary, fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: 'Tulis komentar...',
                        hintStyle: TextStyle(color: CommunityColors.textMuted, fontSize: 13),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: _submittingComment
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(CommunityColors.primary),
                          ),
                        )
                      : const Icon(Icons.send_rounded, color: CommunityColors.primary),
                  onPressed: _submittingComment ? null : _addComment,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
