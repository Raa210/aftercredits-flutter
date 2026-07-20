import 'dart:async';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:aftercredits/core/theme/app_theme.dart';
import 'package:aftercredits/core/services/tmdb_service.dart';
import 'package:aftercredits/core/services/community_service.dart';
import 'package:aftercredits/models/movie_model.dart';
import 'package:aftercredits/features/movie_detail/movie_detail_screen.dart';
import 'package:aftercredits/features/home/tabs/community/user_profile_screen.dart';

class SearchTab extends StatefulWidget {
  const SearchTab({super.key});

  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {
  final TextEditingController _controller = TextEditingController();
  final TmdbService _tmdb = TmdbService();

  bool _hasQuery = false;
  bool _searching = false;
  List<MovieModel> _searchResults = [];
  List<Map<String, dynamic>> _userResults = [];
  Timer? _debounce;

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String val) {
    setState(() => _hasQuery = val.isNotEmpty);

    _debounce?.cancel();
    if (val.isEmpty) {
      setState(() {
        _searchResults = [];
        _userResults = [];
        _searching = false;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (!mounted) return;
      setState(() => _searching = true);
      final futures = await Future.wait([
        _tmdb.searchMovies(val),
        CommunityService().searchUsers(val),
      ]);
      if (!mounted) return;
      setState(() {
        _searchResults = futures[0] as List<MovieModel>;
        _userResults = futures[1] as List<Map<String, dynamic>>;
        _searching = false;
      });
    });
  }

  void _openDetail(BuildContext context, MovieModel movie) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => MovieDetailScreen(movie: movie)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.darkPrimary,
        title: const Text(
          'Cari Film',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.darkTertiary,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border, width: 0.5),
                    ),
                    child: Row(
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 14),
                          child: Icon(Icons.search_rounded,
                              color: AppColors.textMuted, size: 20),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            autofocus: false,
                            onChanged: _onSearchChanged,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Cari film, pengguna, aktor...',
                              hintStyle: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 14,
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding:
                                  EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                        if (_hasQuery)
                          IconButton(
                            icon: const Icon(Icons.close_rounded,
                                color: AppColors.textMuted, size: 18),
                            onPressed: () {
                              _controller.clear();
                              _onSearchChanged('');
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _hasQuery ? _buildResults(context) : _buildEmptyState(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 40),
          const SizedBox(height: 12),
          const Text(
            'Ketik nama film atau username untuk mencari.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(BuildContext context) {
    if (_searching) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accentRed),
      );
    }

    if (_searchResults.isEmpty && _userResults.isEmpty && _hasQuery) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off_rounded,
                color: AppColors.textMuted, size: 40),
            const SizedBox(height: 12),
            Text(
              'Tidak ada hasil untuk\n"${_controller.text}"',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        // User results section
        if (_userResults.isNotEmpty) ...[
          _buildUserResultsSection(),
          const SizedBox(height: 16),
        ],
        // Movie results
        if (_searchResults.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text('Film', style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
          ),
          ...List.generate(_searchResults.length, (index) {
            final movie = _searchResults[index];
            return Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: movie.posterUrl != null
                        ? Image.network(
                            movie.posterUrl!,
                            width: 42,
                            height: 62,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 42, height: 62,
                              color: AppColors.darkTertiary,
                              child: const Icon(Icons.movie_outlined, size: 20, color: AppColors.textMuted),
                            ),
                          )
                        : Container(
                            width: 42, height: 62,
                            color: AppColors.darkTertiary,
                            child: const Icon(Icons.movie_outlined, size: 20, color: AppColors.textMuted),
                          ),
                  ),
                  title: Text(movie.title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                  subtitle: Text('${movie.year}  •  ★ ${movie.ratingFormatted}', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                  onTap: () => _openDetail(context, movie),
                ),
                if (index < _searchResults.length - 1)
                  const Divider(color: AppColors.border, height: 1, thickness: 0.5),
              ],
            );
          }),
        ],
      ],
    );
  }

  Widget _buildUserResultsSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.darkTertiary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: AppColors.accentRed.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.people_rounded, size: 14, color: AppColors.accentRed),
              ),
              const SizedBox(width: 8),
              const Text('Pengguna', style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
            ],
          ),
          const Divider(color: AppColors.border, height: 20, thickness: 0.5),
          ...List.generate(_userResults.length, (i) {
            final u = _userResults[i];
            return Padding(
              padding: EdgeInsets.only(bottom: i < _userResults.length - 1 ? 6 : 0),
              child: InkWell(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => UserProfileScreen(
                      userId: u['id'] as String,
                      username: u['username'] as String? ?? '',
                      avatarUrl: u['avatar_url'] as String?,
                    ),
                  ));
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.darkPrimary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.border,
                        backgroundImage: u['avatar_url'] != null ? NetworkImage(u['avatar_url'] as String) : null,
                        child: u['avatar_url'] == null ? const Icon(Icons.person_rounded, color: AppColors.textMuted, size: 20) : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('@${u['username']}', style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                            const Text('Lihat profil', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 18),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
