import 'package:flutter/material.dart';
import 'package:aftercredits/core/theme/app_theme.dart';
import 'package:aftercredits/shared/widgets/movie_card.dart';

class SearchTab extends StatefulWidget {
  const SearchTab({super.key});

  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {
  final TextEditingController _controller = TextEditingController();
  bool _hasQuery = false;

  final List<Map<String, dynamic>> _trendingSearches = [
    {'title': 'Inception', 'year': '2010', 'rating': 8.8, 'poster': 'https://image.tmdb.org/t/p/w185/ljsZTbVsrQSqNgWeRnEkekVgiOfH.jpg'},
    {'title': 'Interstellar', 'year': '2014', 'rating': 8.6, 'poster': 'https://image.tmdb.org/t/p/w185/gEU2QniE6E77NI6lCU6MxlNBvIx.jpg'},
    {'title': 'Parasite', 'year': '2019', 'rating': 8.5, 'poster': 'https://image.tmdb.org/t/p/w185/7IiTTgloJzvGI1TAYymCfbfl3vT.jpg'},
    {'title': 'Dune: Part Two', 'year': '2024', 'rating': 8.0, 'poster': 'https://image.tmdb.org/t/p/w185/1pdfLvkbY9ohJlCjQH2CZjjYVvJ.jpg'},
    {'title': 'Oppenheimer', 'year': '2023', 'rating': 8.3, 'poster': 'https://image.tmdb.org/t/p/w185/8Gxv8gSFCU0XGDykEGv7zR1n2ua.jpg'},
    {'title': 'Blade Runner 2049', 'year': '2017', 'rating': 8.0, 'poster': 'https://image.tmdb.org/t/p/w185/gajva2L0rPYkEWjzgFlBXCAVBE5.jpg'},
  ];

  final List<String> _genres = [
    'Action', 'Drama', 'Sci-Fi', 'Comedy', 'Thriller',
    'Horror', 'Romance', 'Animation', 'Documentary', 'Crime',
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
                            onChanged: (val) =>
                                setState(() => _hasQuery = val.isNotEmpty),
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                            ),
                            decoration: const InputDecoration(
                              hintText:
                                  'Cari film, aktor, sutradara...',
                              hintStyle: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 14,
                              ),
                              border: InputBorder.none,
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
                              setState(() => _hasQuery = false);
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
            child: _hasQuery ? _buildResults() : _buildDiscover(),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscover() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Genre browse
          const Text(
            'Jelajahi Genre',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 3.2,
            ),
            itemCount: _genres.length,
            itemBuilder: (context, index) {
              final colors = [
                AppColors.accentRed,
                const Color(0xFF7C3AED),
                const Color(0xFF0EA5E9),
                const Color(0xFF10B981),
                const Color(0xFFF59E0B),
                AppColors.accentOrange,
                const Color(0xFFEC4899),
                const Color(0xFF6366F1),
                const Color(0xFF14B8A6),
                const Color(0xFF8B5CF6),
              ];
              final color = colors[index % colors.length];
              return GestureDetector(
                onTap: () {},
                child: Container(
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: color.withOpacity(0.3)),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _genres[index],
                    style: TextStyle(
                      color: color,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 28),

          // Trending films
          const Text(
            'Sedang Trending',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.65,
            ),
            itemCount: _trendingSearches.length,
            itemBuilder: (context, index) {
              final movie = _trendingSearches[index];
              return MovieCard(
                title: movie['title'] as String,
                year: movie['year'] as String,
                rating: (movie['rating'] as num).toDouble(),
                posterUrl: movie['poster'] as String?,
                onTap: () {},
              );
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildResults() {
    // Filtered list (mock)
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _trendingSearches.length,
      separatorBuilder: (_, __) => const Divider(
        color: AppColors.border,
        height: 1,
        thickness: 0.5,
      ),
      itemBuilder: (context, index) {
        final movie = _trendingSearches[index];
        return ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              movie['poster'] as String,
              width: 42,
              height: 62,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 42,
                height: 62,
                color: AppColors.darkTertiary,
                child: const Icon(Icons.movie_outlined,
                    size: 20, color: AppColors.textMuted),
              ),
            ),
          ),
          title: Text(
            movie['title'] as String,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            '${movie['year']} • ★ ${movie['rating']}',
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
            ),
          ),
          trailing: const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textMuted,
          ),
          onTap: () {},
        );
      },
    );
  }
}
