import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'community/community_colors.dart';
import 'community/widgets/community_header.dart';
import 'community/widgets/category_tabs.dart';
import 'community/widgets/discussion_card.dart';
import 'community/widgets/trending_discussion_card.dart';
import 'community/widgets/popular_movies_card.dart';

class CommunityTab extends StatefulWidget {
  const CommunityTab({super.key});

  @override
  State<CommunityTab> createState() => _CommunityTabState();
}

class _CommunityTabState extends State<CommunityTab> {
  int _selectedCategory = 0;

  final List<String> _categories = [
    'Semua',
    'Ending',
    'Teori',
    'Spoiler Talk',
    'Diskusi',
  ];

  // ─── Data Thread (sama seperti sebelumnya, ditambah views & posterUrl) ────
  final List<Map<String, dynamic>> _threads = [
    {
      'title': 'Inception (2010) Ending Explained',
      'preview':
          'Apa yang sebenarnya terjadi saat totem milik Cobb di ending film? Mari bahas berbagai teori dan interpretasi!',
      'author': 'FilmLover99',
      'time': '2 jam lalu',
      'likes': 126,
      'comments': 2100,
      'views': 12000,
      'tag': 'ENDING',
      'tagColor': 0xFFE50914,
      'movie': 'Inception',
      'posterUrl':
          'https://image.tmdb.org/t/p/w342/oYuLEt3zVCKq57qu2F8dT7NIa6f.jpg',
    },
    {
      'title': 'The Prestige (2006) – Spoiler',
      'preview':
          'Teori paling gila: ternyata ada token milik Cobb yang masuk akal tentang The Prestige juga...',
      'author': 'CinephileID',
      'time': '5 jam lalu',
      'likes': 94,
      'comments': 1600,
      'views': 8000,
      'tag': 'SPOILER',
      'tagColor': 0xFFFF6B35,
      'movie': 'The Prestige',
      'posterUrl':
          'https://image.tmdb.org/t/p/w342/tRNlZbFpCiZpnEGN7AKMJbr93A4.jpg',
    },
    {
      'title': 'Dune: Part Two (2024) — Discussion',
      'preview':
          'Apakah Cassier berada di masa depan atau apakah itu hanya visi Paul Atreides?',
      'author': 'DuneWatcher',
      'time': '1 hari lalu',
      'likes': 79,
      'comments': 3200,
      'views': 15000,
      'tag': 'DISKUSI',
      'tagColor': 0xFF0EA5E9,
      'movie': 'Dune Part Two',
      'posterUrl':
          'https://image.tmdb.org/t/p/w342/8b8R8l88Qje9dn9OE8PY05Nez7C.jpg',
    },
    {
      'title': 'Interstellar (2014) – Theory',
      'preview':
          'Apakah mereka benar-benar meninggalkan dimensi kita? Teori tentang tesseract dan waktu.',
      'author': 'SpaceNerd',
      'time': '2 hari lalu',
      'likes': 68,
      'comments': 1100,
      'views': 9500,
      'tag': 'TEORI',
      'tagColor': 0xFF7C3AED,
      'movie': 'Interstellar',
      'posterUrl':
          'https://image.tmdb.org/t/p/w342/gEU2QniE6E77NI6lCU6MxlNBvIx.jpg',
    },
    {
      'title': 'The Dark Knight Joker Theory',
      'preview':
          'Joker bukan villain biasa. Dia adalah agen chaos yang menguji moralitas Gotham.',
      'author': 'BatFan',
      'time': '3 hari lalu',
      'likes': 98,
      'comments': 1800,
      'views': 11000,
      'tag': 'TEORI',
      'tagColor': 0xFF7C3AED,
      'movie': 'The Dark Knight',
      'posterUrl':
          'https://image.tmdb.org/t/p/w342/qJ2tW6WMUDux911BIXW5nhkAQ4F.jpg',
    },
    {
      'title': 'Fight Club Alternate Ending',
      'preview':
          'Bagaimana jika Tyler Durden sebenarnya nyata? Ending alternatif yang mengejutkan.',
      'author': 'FirstRule',
      'time': '4 hari lalu',
      'likes': 87,
      'comments': 1300,
      'views': 7600,
      'tag': 'ENDING',
      'tagColor': 0xFFE50914,
      'movie': 'Fight Club',
      'posterUrl':
          'https://image.tmdb.org/t/p/w342/pB8BM7pdSp6B6Ih7QZ4DrQ3PmJK.jpg',
    },
  ];

  // ─── Data Sidebar: Film Populer ──────────────────────────────────────
  final List<Map<String, dynamic>> _popularMovies = [
    {
      'title': 'Dune: Part Two',
      'posterUrl':
          'https://image.tmdb.org/t/p/w342/8b8R8l88Qje9dn9OE8PY05Nez7C.jpg',
    },
    {
      'title': 'Oppenheimer',
      'posterUrl':
          'https://image.tmdb.org/t/p/w342/8Gxv8gSFCU0XGDykEGv7zR1n2ua.jpg',
    },
    {
      'title': 'Spider-Man: No Way Home',
      'posterUrl':
          'https://image.tmdb.org/t/p/w342/1g0dhYtq4irTY1GPXvft6k4YLjm.jpg',
    },
    {
      'title': 'The Batman',
      'posterUrl':
          'https://image.tmdb.org/t/p/w342/74xTEgt7R36Fpooo50r9T25onhq.jpg',
    },
  ];

  /// Thread yang sudah difilter berdasarkan kategori.
  List<Map<String, dynamic>> get _filteredThreads {
    if (_selectedCategory == 0) return _threads;

    final categoryTag = _categoryToTag(_categories[_selectedCategory]);
    return _threads
        .where((t) =>
            (t['tag'] as String).toUpperCase() == categoryTag.toUpperCase())
        .toList();
  }

  String _categoryToTag(String category) {
    switch (category.toLowerCase()) {
      case 'ending':
        return 'ENDING';
      case 'teori':
        return 'TEORI';
      case 'spoiler talk':
        return 'SPOILER';
      case 'diskusi':
        return 'DISKUSI';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CommunityColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return CustomScrollView(
              slivers: [
                // ─── Header ────────────────────────────────
                SliverToBoxAdapter(
                  child: FadeInDown(
                    duration: const Duration(milliseconds: 400),
                    child: const CommunityHeader(),
                  ),
                ),

                // ─── Category Tabs ─────────────────────────
                SliverToBoxAdapter(
                  child: FadeInDown(
                    delay: const Duration(milliseconds: 100),
                    duration: const Duration(milliseconds: 400),
                    child: Padding(
                      padding: const EdgeInsets.only(
                        bottom: CommunitySpacing.md,
                      ),
                      child: CategoryTabs(
                        categories: _categories,
                        selectedIndex: _selectedCategory,
                        onSelected: (index) {
                          setState(() => _selectedCategory = index);
                        },
                      ),
                    ),
                  ),
                ),

                // ─── Divider ───────────────────────────────
                const SliverToBoxAdapter(
                  child: Divider(
                    color: CommunityColors.divider,
                    height: 1,
                    thickness: 1,
                  ),
                ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: CommunitySpacing.md),
                ),

                // ─── Content (Responsive) ──────────────────
                SliverToBoxAdapter(
                  child: _buildResponsiveContent(constraints),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildResponsiveContent(BoxConstraints constraints) {
    final width = constraints.maxWidth;
    final isDesktop = width >= 1024;
    final isTablet = width >= 600 && width < 1024;

    if (isDesktop || isTablet) {
      return _buildTwoColumnLayout(isTablet: isTablet);
    }
    return _buildMobileLayout();
  }

  /// Layout dua kolom untuk desktop/tablet.
  Widget _buildTwoColumnLayout({bool isTablet = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: CommunitySpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Kolom Kiri: Thread List (~70%) ─────────
          Expanded(
            flex: isTablet ? 6 : 7,
            child: _buildThreadList(),
          ),
          const SizedBox(width: CommunitySpacing.md),

          // ─── Kolom Kanan: Sidebar (~30%) ────────────
          Expanded(
            flex: isTablet ? 4 : 3,
            child: _buildSidebar(),
          ),
        ],
      ),
    );
  }

  /// Layout mobile: thread list lalu sidebar di bawahnya.
  Widget _buildMobileLayout() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: CommunitySpacing.md),
      child: Column(
        children: [
          _buildThreadList(),
          const SizedBox(height: CommunitySpacing.lg),
          _buildSidebar(),
          const SizedBox(height: CommunitySpacing.xl),
        ],
      ),
    );
  }

  Widget _buildThreadList() {
    final threads = _filteredThreads;

    if (threads.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.forum_outlined,
                color: CommunityColors.textMuted,
                size: 48,
              ),
              const SizedBox(height: CommunitySpacing.md),
              const Text(
                'Belum ada diskusi untuk kategori ini.',
                style: TextStyle(
                  color: CommunityColors.textMuted,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: List.generate(
        threads.length,
        (index) => Padding(
          padding: const EdgeInsets.only(bottom: CommunitySpacing.md),
          child: FadeInUp(
            delay: Duration(milliseconds: 60 * index),
            duration: const Duration(milliseconds: 400),
            child: DiscussionCard(thread: threads[index]),
          ),
        ),
      ),
    );
  }

  Widget _buildSidebar() {
    return Column(
      children: [
        // 1. Trending Discussion
        FadeInRight(
          delay: const Duration(milliseconds: 200),
          duration: const Duration(milliseconds: 400),
          child: TrendingDiscussionCard(
            threads: _threads,
          ),
        ),
        const SizedBox(height: CommunitySpacing.md),

        // 2. Film Populer Minggu Ini
        FadeInRight(
          delay: const Duration(milliseconds: 300),
          duration: const Duration(milliseconds: 400),
          child: PopularMoviesCard(
            movies: _popularMovies,
          ),
        ),
      ],
    );
  }
}
