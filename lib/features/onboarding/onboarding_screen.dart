import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:animate_do/animate_do.dart';
import 'package:aftercredits/core/theme/app_theme.dart';
import 'package:aftercredits/features/auth/login_screen.dart';
import 'package:aftercredits/core/services/tmdb_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingData> _pages = [
    _OnboardingData(
      title: 'Temukan\nHidden Gems 💎',
      subtitle:
          'Film luar biasa yang belum banyak dikenal menunggumu. Rekomendasi harian dipersonalisasi khusus seleramu.',
      badge: 'Discover',
      posterUrls: [
        'https://image.tmdb.org/t/p/w342/8Gxv8gSFCU0XGDykEGv7zR1n2ua.jpg',
        'https://image.tmdb.org/t/p/w342/gEU2QniE6E77NI6lCU6MxlNBvIx.jpg',
        'https://image.tmdb.org/t/p/w342/8Vt6mWEReuy4Of61Lnj5Xj704m8.jpg',
        'https://image.tmdb.org/t/p/w342/pB8BM7pdSp6B6Ih7QZ4DrQ3PmJK.jpg',
        'https://image.tmdb.org/t/p/w342/t6HIqrRAclMCA60NsSmeqe9RmNV.jpg',
        'https://image.tmdb.org/t/p/w342/6CoRTJTmijhBLJTUNoVSUNxZMEI.jpg',
      ],
      accentColor: AppColors.accentRed,
      gradientColors: [AppColors.accentRed, Color(0xFFFF6B35)],
      icon: Icons.auto_awesome_rounded,
    ),
    _OnboardingData(
      title: 'Diskusikan\nEnding Film 🎬',
      subtitle:
          'Bergabung dengan komunitas cinephile. Debatkan teori, bahas twist, dan ungkap makna tersembunyi bersama-sama.',
      badge: 'Community',
      posterUrls: [
        'https://image.tmdb.org/t/p/w342/8Vt6mWEReuy4Of61Lnj5Xj704m8.jpg',
        'https://image.tmdb.org/t/p/w342/8Gxv8gSFCU0XGDykEGv7zR1n2ua.jpg',
        'https://image.tmdb.org/t/p/w342/t6HIqrRAclMCA60NsSmeqe9RmNV.jpg',
        'https://image.tmdb.org/t/p/w342/gEU2QniE6E77NI6lCU6MxlNBvIx.jpg',
        'https://image.tmdb.org/t/p/w342/6CoRTJTmijhBLJTUNoVSUNxZMEI.jpg',
        'https://image.tmdb.org/t/p/w342/pB8BM7pdSp6B6Ih7QZ4DrQ3PmJK.jpg',
      ],
      accentColor: Color(0xFF7C3AED),
      gradientColors: [Color(0xFF7C3AED), Color(0xFFDB2777)],
      icon: Icons.forum_rounded,
    ),
    _OnboardingData(
      title: 'Kenali Selera\nFilmmu 📊',
      subtitle:
          'Lacak setiap film yang kamu tonton. Lihat profil seleramu divisualisasikan — genre favoritmu, rating rata-rata, dan lebih banyak lagi.',
      badge: 'Taste Profile',
      posterUrls: [
        'https://image.tmdb.org/t/p/w342/pB8BM7pdSp6B6Ih7QZ4DrQ3PmJK.jpg',
        'https://image.tmdb.org/t/p/w342/6CoRTJTmijhBLJTUNoVSUNxZMEI.jpg',
        'https://image.tmdb.org/t/p/w342/gEU2QniE6E77NI6lCU6MxlNBvIx.jpg',
        'https://image.tmdb.org/t/p/w342/8Vt6mWEReuy4Of61Lnj5Xj704m8.jpg',
        'https://image.tmdb.org/t/p/w342/8Gxv8gSFCU0XGDykEGv7zR1n2ua.jpg',
        'https://image.tmdb.org/t/p/w342/t6HIqrRAclMCA60NsSmeqe9RmNV.jpg',
      ],
      accentColor: Color(0xFF0EA5E9),
      gradientColors: [Color(0xFF0EA5E9), Color(0xFF6366F1)],
      icon: Icons.pie_chart_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fetchDynamicPosters();
  }

  Future<void> _fetchDynamicPosters() async {
    try {
      final tmdb = TmdbService();
      final movies = await tmdb.getPopular();
      final validPosters = movies
          .where((m) => m.posterUrl != null)
          .map((m) => m.posterUrl!)
          .toList();
      if (validPosters.length >= 18 && mounted) {
        setState(() {
          _pages[0].posterUrls = validPosters.sublist(0, 6);
          _pages[1].posterUrls = validPosters.sublist(6, 12);
          _pages[2].posterUrls = validPosters.sublist(12, 18);
        });
      }
    } catch (_) {
      // Abaikan jika offline, fallback static tetap aktif
    }
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);

    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, animation, __) => const LoginScreen(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkPrimary,
      body: Stack(
        children: [
          // Page content
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemCount: _pages.length,
            itemBuilder: (context, index) {
              return _OnboardingPage(
                data: _pages[index],
                isActive: _currentPage == index,
              );
            },
          ),

          // Bottom controls overlay
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomControls(),
          ),

          // Back button
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 24,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 250),
              opacity: _currentPage > 0 ? 1.0 : 0.0,
              child: IgnorePointer(
                ignoring: _currentPage == 0,
                child: TextButton.icon(
                  onPressed: () {
                    if (_currentPage > 0) {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: AppColors.textPrimary,
                    size: 18,
                  ),
                  label: const Text(
                    'Kembali',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Skip button
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 24,
            child: _currentPage < _pages.length - 1
                ? TextButton(
                    onPressed: _completeOnboarding,
                    child: Text(
                      'Lewati',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    final isLast = _currentPage == _pages.length - 1;
    final currentAccent = _pages[_currentPage].accentColor;

    return Container(
      padding: EdgeInsets.fromLTRB(
        28,
        24,
        28,
        MediaQuery.of(context).padding.bottom + 32,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            AppColors.darkPrimary.withOpacity(0.95),
            AppColors.darkPrimary,
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Page indicator
          SmoothPageIndicator(
            controller: _pageController,
            count: _pages.length,
            effect: ExpandingDotsEffect(
              activeDotColor: currentAccent,
              dotColor: AppColors.border,
              dotHeight: 6,
              dotWidth: 6,
              expansionFactor: 4,
              spacing: 6,
            ),
          ),
          const SizedBox(height: 28),

          // Action buttons
          Row(
            children: [
              if (_currentPage > 0) ...[
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.darkTertiary,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _pageController.previousPage(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      child: const Center(
                        child: Icon(
                          Icons.arrow_back_rounded,
                          color: AppColors.textPrimary,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _pages[_currentPage].gradientColors,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: currentAccent.withOpacity(0.35),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: isLast
                          ? _completeOnboarding
                          : () => _pageController.nextPage(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOut,
                            ),
                      borderRadius: BorderRadius.circular(16),
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isLast ? 'Mulai Sekarang' : 'Lanjut',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              isLast
                                  ? Icons.rocket_launch_rounded
                                  : Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Individual onboarding page
// ─────────────────────────────────────────────────────────

class _OnboardingPage extends StatelessWidget {
  final _OnboardingData data;
  final bool isActive;

  const _OnboardingPage({required this.data, required this.isActive});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Stack(
      children: [
        // Background gradient
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.5),
                radius: 1.2,
                colors: [
                  data.accentColor.withOpacity(0.15),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Floating poster grid
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: size.height * 0.60,
          child: _PosterGrid(
            posterUrls: data.posterUrls,
            accent: data.accentColor,
          ),
        ),

        // Fade overlay at bottom of image area
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: size.height * 0.65,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.4, 1.0],
                colors: [
                  Colors.transparent,
                  AppColors.darkPrimary.withOpacity(0.7),
                  AppColors.darkPrimary,
                ],
              ),
            ),
          ),
        ),

        // Content
        Positioned(
          bottom: 160,
          left: 0,
          right: 0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Badge
                FadeInUp(
                  delay: const Duration(milliseconds: 100),
                  duration: const Duration(milliseconds: 500),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: data.accentColor.withOpacity(0.15),
                      border: Border.all(
                        color: data.accentColor.withOpacity(0.4),
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(data.icon, size: 14, color: data.accentColor),
                        const SizedBox(width: 6),
                        Text(
                          data.badge,
                          style: TextStyle(
                            color: data.accentColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Title
                FadeInUp(
                  delay: const Duration(milliseconds: 200),
                  duration: const Duration(milliseconds: 500),
                  child: Text(
                    data.title,
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                      height: 1.1,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Subtitle
                FadeInUp(
                  delay: const Duration(milliseconds: 300),
                  duration: const Duration(milliseconds: 500),
                  child: Text(
                    data.subtitle,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondary,
                      height: 1.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────
// Poster grid widget (staggered layout)
// ─────────────────────────────────────────────────────────

class _PosterGrid extends StatelessWidget {
  final List<String> posterUrls;
  final Color accent;

  const _PosterGrid({required this.posterUrls, required this.accent});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final posterW = constraints.maxWidth / 3.3;
        final posterH = posterW * 1.5;
        final List<Map<String, double>> positions = [
          {'left': 0, 'top': 40},
          {'left': posterW * 1.05, 'top': 10},
          {'left': posterW * 2.1, 'top': 30},
          {'left': posterW * 0.3, 'top': posterH * 0.85},
          {'left': posterW * 1.35, 'top': posterH * 0.9},
          {'left': posterW * 2.4, 'top': posterH * 0.82},
        ];

        return Stack(
          clipBehavior: Clip.none,
          children: List.generate(
            posterUrls.length < 6 ? posterUrls.length : 6,
            (i) => Positioned(
              left: positions[i]['left'],
              top: positions[i]['top'],
              child: Transform.rotate(
                angle: [-0.08, 0.05, -0.06, 0.09, -0.04, 0.07][i],
                child: _PosterCard(
                  url: posterUrls[i],
                  width: posterW,
                  height: posterH,
                  accent: accent,
                  delay: Duration(milliseconds: 100 * i),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PosterCard extends StatelessWidget {
  final String url;
  final double width;
  final double height;
  final Color accent;
  final Duration delay;

  const _PosterCard({
    required this.url,
    required this.width,
    required this.height,
    required this.accent,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return FadeIn(
      delay: delay,
      duration: const Duration(milliseconds: 600),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: accent.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: AppColors.darkTertiary,
              child: const Icon(Icons.movie, color: AppColors.textMuted),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Data model
// ─────────────────────────────────────────────────────────

class _OnboardingData {
  final String title;
  final String subtitle;
  final String badge;
  List<String> posterUrls;
  final Color accentColor;
  final List<Color> gradientColors;
  final IconData icon;

  _OnboardingData({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.posterUrls,
    required this.accentColor,
    required this.gradientColors,
    required this.icon,
  });
}
