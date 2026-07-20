import 'dart:async';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:aftercredits/core/services/community_service.dart';
import 'package:aftercredits/core/services/tmdb_service.dart';
import 'package:aftercredits/models/movie_model.dart';
import 'community/community_colors.dart';
import 'community/widgets/community_header.dart';
import 'community/widgets/category_tabs.dart';
import 'community/widgets/discussion_card.dart';
import 'community/widgets/trending_discussion_card.dart';
import 'community/widgets/popular_movies_card.dart';
import 'community/thread_detail_screen.dart';
import 'community/widgets/create_thread_dialog.dart';

class CommunityTab extends StatefulWidget {
  const CommunityTab({super.key});

  @override
  State<CommunityTab> createState() => _CommunityTabState();
}

class _CommunityTabState extends State<CommunityTab> {
  int _selectedCategory = 0;
  String _searchQuery = '';
  Timer? _searchDebounce;

  // Pagination & Loading States
  final List<Map<String, dynamic>> _threads = [];
  bool _loadingInitial = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  final int _limit = 10;
  String? _error;

  final ScrollController _scrollController = ScrollController();

  // Sidebar Data
  List<Map<String, dynamic>> _trendingThreads = [];
  List<Map<String, dynamic>> _popularMovies = [];
  bool _loadingSidebar = true;

  final List<String> _categories = [
    'Semua',
    'Ending',
    'Teori',
    'Spoiler Talk',
    'Diskusi',
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadInitialData();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    
    // Picu load more ketika scroll mencapai 85% dari batas bawah
    if (currentScroll >= maxScroll * 0.85 && !_loadingMore && _hasMore && _error == null) {
      _loadMoreThreads();
    }
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _loadingInitial = true;
      _currentPage = 1;
      _threads.clear();
      _error = null;
      _hasMore = true;
    });

    try {
      final results = await CommunityService().getThreads(
        category: _categories[_selectedCategory],
        query: _searchQuery,
        page: _currentPage,
        limit: _limit,
      );

      setState(() {
        _threads.addAll(results);
        _loadingInitial = false;
        if (results.length < _limit) {
          _hasMore = false;
        }
      });
    } catch (e) {
      setState(() {
        _loadingInitial = false;
        _error = e.toString().replaceAll('Exception: ', '');
      });
    }

    _loadSidebarData();
  }

  Future<void> _loadMoreThreads() async {
    if (_loadingMore || !_hasMore) return;

    setState(() => _loadingMore = true);
    final nextPage = _currentPage + 1;

    try {
      final results = await CommunityService().getThreads(
        category: _categories[_selectedCategory],
        query: _searchQuery,
        page: nextPage,
        limit: _limit,
      );

      setState(() {
        _currentPage = nextPage;
        _threads.addAll(results);
        _loadingMore = false;
        if (results.length < _limit) {
          _hasMore = false;
        }
      });
    } catch (_) {
      setState(() => _loadingMore = false);
    }
  }

  Future<void> _loadSidebarData() async {
    setState(() => _loadingSidebar = true);
    try {
      final futures = await Future.wait([
        CommunityService().getTrendingThreads(),
        TmdbService().getTrendingWeek(),
      ]);

      final trending = futures[0] as List<Map<String, dynamic>>;
      final movies = futures[1] as List<MovieModel>;

      final parsedMovies = movies.map((m) {
        return {
          'title': m.title,
          'posterUrl': m.posterUrl,
        };
      }).toList();

      setState(() {
        _trendingThreads = trending;
        _popularMovies = parsedMovies;
        _loadingSidebar = false;
      });
    } catch (_) {
      setState(() => _loadingSidebar = false);
    }
  }

  void _onSearchChanged(String query) {
    if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _searchQuery = query;
      });
      _loadInitialData();
    });
  }

  void _onCreateThreadPressed() {
    showDialog(
      context: context,
      builder: (context) => CreateThreadDialog(
        onSuccess: _loadInitialData,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CommunityColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return RefreshIndicator(
              onRefresh: _loadInitialData,
              color: CommunityColors.primary,
              backgroundColor: CommunityColors.card,
              child: CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // ─── Header ────────────────────────────────
                  SliverToBoxAdapter(
                    child: FadeInDown(
                      duration: const Duration(milliseconds: 400),
                      child: CommunityHeader(
                        onCreateThread: _onCreateThreadPressed,
                        onSearch: _onSearchChanged,
                      ),
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
                            _loadInitialData();
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

                  // ─── Content Area ──────────────────────────
                  SliverToBoxAdapter(
                    child: _buildResponsiveContent(constraints),
                  ),
                ],
              ),
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

  Widget _buildTwoColumnLayout({bool isTablet = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: CommunitySpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Kolom Kiri: Thread List
          Expanded(
            flex: isTablet ? 6 : 7,
            child: _buildMainColumn(),
          ),
          const SizedBox(width: CommunitySpacing.md),

          // Kolom Kanan: Sidebar
          Expanded(
            flex: isTablet ? 4 : 3,
            child: _buildSidebarColumn(),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: CommunitySpacing.md),
      child: Column(
        children: [
          _buildMainColumn(),
          const SizedBox(height: CommunitySpacing.lg),
          _buildSidebarColumn(),
          const SizedBox(height: CommunitySpacing.xl),
        ],
      ),
    );
  }

  Widget _buildMainColumn() {
    if (_loadingInitial) {
      return _buildLoadingPlaceholder();
    }

    if (_error != null) {
      return _buildErrorPlaceholder();
    }

    if (_threads.isEmpty) {
      return _buildEmptyPlaceholder();
    }

    return Column(
      children: [
        ...List.generate(
          _threads.length,
          (index) {
            final t = _threads[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: CommunitySpacing.md),
              child: FadeInUp(
                delay: Duration(milliseconds: 40 * index),
                duration: const Duration(milliseconds: 300),
                child: DiscussionCard(
                  thread: t,
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ThreadDetailScreen(thread: t),
                      ),
                    );
                    _loadInitialData(); // Refresh untuk update stats (like/comment/view)
                  },
                ),
              ),
            );
          },
        ),
        if (_loadingMore)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(CommunityColors.primary),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSidebarColumn() {
    if (_loadingSidebar) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(CommunityColors.primary),
          ),
        ),
      );
    }

    return Column(
      children: [
        if (_trendingThreads.isNotEmpty) ...[
          TrendingDiscussionCard(
            threads: _trendingThreads,
          ),
          const SizedBox(height: CommunitySpacing.md),
        ],
        if (_popularMovies.isNotEmpty)
          PopularMoviesCard(
            movies: _popularMovies,
          ),
      ],
    );
  }

  // ─── States Placeholders ──────────────────────────────────

  Widget _buildLoadingPlaceholder() {
    return Column(
      children: List.generate(
        3,
        (index) => Padding(
          padding: const EdgeInsets.only(bottom: CommunitySpacing.md),
          child: Container(
            height: 160,
            decoration: BoxDecoration(
              color: CommunityColors.card,
              borderRadius: BorderRadius.circular(CommunityRadius.lg),
              border: Border.all(color: CommunityColors.divider, width: 0.5),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(CommunityColors.primary),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorPlaceholder() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.error_outline_rounded, color: CommunityColors.primary, size: 48),
            const SizedBox(height: 16),
            Text(
              _error ?? 'Terjadi kesalahan sistem',
              textAlign: TextAlign.center,
              style: const TextStyle(color: CommunityColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadInitialData,
              style: ElevatedButton.styleFrom(backgroundColor: CommunityColors.primary),
              child: const Text('Coba Lagi', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyPlaceholder() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 16),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.forum_outlined, color: CommunityColors.textMuted, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Belum ada diskusi untuk kategori atau pencarian ini.',
              textAlign: TextAlign.center,
              style: TextStyle(color: CommunityColors.textMuted, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
