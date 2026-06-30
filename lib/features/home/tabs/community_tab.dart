import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../../core/theme/app_theme.dart';

class CommunityTab extends StatefulWidget {
  const CommunityTab({super.key});

  @override
  State<CommunityTab> createState() => _CommunityTabState();
}

class _CommunityTabState extends State<CommunityTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> _tabs = ['Semua', 'Ending Discussion', 'Teori', 'Spoiler Talk'];

  final List<Map<String, dynamic>> _threads = [
    {
      'title': 'Inception (2010) Ending Explained',
      'preview': 'Apa yang sebenarnya terjadi saat totem milik Cobb di ending film?',
      'author': 'FilmLover99',
      'time': '2 jam lalu',
      'likes': 126,
      'comments': 2100,
      'tag': 'ENDING',
      'tagColor': 0xFFE50914,
      'movie': 'Inception',
    },
    {
      'title': 'The Prestige (2006) - Spoiler',
      'preview': 'Teori paling gila: ternyata ada token milik Cobb yang masuk akal tentang The Prestige juga...',
      'author': 'CinephileID',
      'time': '5 jam lalu',
      'likes': 94,
      'comments': 1600,
      'tag': 'SPOILER',
      'tagColor': 0xFFFF6B35,
      'movie': 'The Prestige',
    },
    {
      'title': 'Dune: Part Two (2024) — Discussion',
      'preview': 'Apakah Cassier berada di masa depan atau apakah itu hanya visi Paul Atreides?',
      'author': 'DuneWatcher',
      'time': '1 hari lalu',
      'likes': 79,
      'comments': 3200,
      'tag': 'DISKUSI',
      'tagColor': 0xFF0EA5E9,
      'movie': 'Dune Part Two',
    },
    {
      'title': 'Parasite (2019) - Analisis Simbol',
      'preview': 'Banjir di Parasite bukan kebetulan. Ini adalah simbol ketidaksetaraan kelas yang...',
      'author': 'KoreanFilmFan',
      'time': '2 hari lalu',
      'likes': 211,
      'comments': 4500,
      'tag': 'TEORI',
      'tagColor': 0xFF7C3AED,
      'movie': 'Parasite',
    },
    {
      'title': 'Blade Runner 2049 — Apa itu manusia?',
      'preview': 'K adalah replicant, tapi justru dia yang paling menunjukkan kemanusiaan di sepanjang film.',
      'author': 'SciFiHead',
      'time': '3 hari lalu',
      'likes': 183,
      'comments': 2800,
      'tag': 'DISKUSI',
      'tagColor': 0xFF0EA5E9,
      'movie': 'Blade Runner 2049',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkPrimary,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            backgroundColor: AppColors.darkPrimary,
            pinned: true,
            floating: true,
            title: const Text(
              'Community',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.edit_rounded, size: 14),
                  label: const Text('Buat Thread'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentRed,
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(56),
              child: Column(
                children: [
                  // Search
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.darkTertiary,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border, width: 0.5),
                      ),
                      child: const Row(
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Icon(Icons.search_rounded,
                                color: AppColors.textMuted, size: 16),
                          ),
                          Text(
                            'Cari diskusi...',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Tabs
                  TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    labelColor: AppColors.accentRed,
                    unselectedLabelColor: AppColors.textMuted,
                    indicatorColor: AppColors.accentRed,
                    indicatorSize: TabBarIndicatorSize.label,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                    dividerColor: AppColors.border,
                    tabs: _tabs.map((t) => Tab(text: t)).toList(),
                  ),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: List.generate(
            _tabs.length,
            (i) => _buildThreadList(),
          ),
        ),
      ),
    );
  }

  Widget _buildThreadList() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: _threads.length + 1,
      separatorBuilder: (_, __) => const Divider(
        color: AppColors.border,
        height: 1,
        thickness: 0.5,
        indent: 16,
        endIndent: 16,
      ),
      itemBuilder: (context, index) {
        if (index == _threads.length) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: TextButton(
                onPressed: () {},
                child: const Text(
                  'Lihat Semua Diskusi →',
                  style: TextStyle(
                    color: AppColors.accentRed,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }
        return FadeInUp(
          delay: Duration(milliseconds: 60 * index),
          duration: const Duration(milliseconds: 400),
          child: _ThreadCard(thread: _threads[index]),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────
// Thread card
// ─────────────────────────────────────────────────────────

class _ThreadCard extends StatelessWidget {
  final Map<String, dynamic> thread;

  const _ThreadCard({required this.thread});

  @override
  Widget build(BuildContext context) {
    final tagColor = Color(thread['tagColor'] as int);

    return InkWell(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Movie thumbnail placeholder
            Container(
              width: 52,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.darkTertiary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.movie_creation_outlined,
                color: AppColors.textMuted,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tag + time row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: tagColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          thread['tag'] as String,
                          style: TextStyle(
                            color: tagColor,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        thread['time'] as String,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Title
                  Text(
                    thread['title'] as String,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Preview
                  Text(
                    thread['preview'] as String,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),

                  // Stats row
                  Row(
                    children: [
                      const Icon(Icons.thumb_up_outlined,
                          size: 13, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        '${thread['likes']}',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Icon(Icons.chat_bubble_outline_rounded,
                          size: 13, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        _formatCount(thread['comments'] as int),
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}
