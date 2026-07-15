import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/app_theme.dart';
import 'core/services/supabase_service.dart';
import 'core/services/user_profile_service.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/home/home_screen.dart';
import 'features/setup/setup_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock portrait orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Transparent status bar + themed nav bar
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppColors.darkSecondary,
  ));

  // Initialize Supabase before anything else
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey, // JWT key for auth
    // publishableKey: SupabaseConfig.publishableKey, // uncomment if needed
  );

  final prefs = await SharedPreferences.getInstance();
  final onboardingDone = prefs.getBool('onboarding_done') ?? false;

  runApp(AfterCreditsApp(showAppIntro: !onboardingDone));
}

class AfterCreditsApp extends StatelessWidget {
  final bool showAppIntro;

  const AfterCreditsApp({super.key, required this.showAppIntro});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AfterCredits',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: _SplashRouter(showAppIntro: showAppIntro),
    );
  }
}

/// Animated splash screen that determines where to route the user.
class _SplashRouter extends StatefulWidget {
  final bool showAppIntro;

  const _SplashRouter({required this.showAppIntro});

  @override
  State<_SplashRouter> createState() => _SplashRouterState();
}

class _SplashRouterState extends State<_SplashRouter>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
          parent: _animController,
          curve: const Interval(0, 0.6)),
    );
    _scaleAnim = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
          parent: _animController, curve: Curves.elasticOut),
    );

    _animController.forward();

    Future.delayed(const Duration(milliseconds: 2200), _route);
  }

  Future<void> _route() async {
    if (!mounted) return;

    final target = await _resolveTarget();
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => target,
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  /// Determines which screen to show after the splash.
  ///
  /// Priority:
  /// 1. Show app intro slides if never seen.
  /// 2. Auth screen if no Supabase session.
  /// 3. Setup screen if session exists but profile is incomplete.
  /// 4. Home screen if everything is good.
  Future<Widget> _resolveTarget() async {
    // Step 1 — first-time app intro
    if (widget.showAppIntro) return const OnboardingScreen();

    // Step 2 — check Supabase session
    final session = supabase.auth.currentSession;
    if (session == null) return const AuthScreen();

    // Step 3 — session exists: check if user has completed setup
    try {
      final profile =
          await UserProfileService().getProfile(session.user.id);
      if (profile == null || !profile.onboardingComplete) {
        return const SetupScreen();
      }
      return const HomeScreen();
    } catch (_) {
      // On any error (network, etc.), fall back to auth
      return const AuthScreen();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkPrimary,
      body: Center(
        child: AnimatedBuilder(
          animation: _animController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnim,
              child: ScaleTransition(scale: _scaleAnim, child: child),
            );
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.accentRed, AppColors.accentOrange],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentRed.withOpacity(0.5),
                      blurRadius: 40,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.movie_creation_rounded,
                  color: Colors.white,
                  size: 44,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'AfterCredits',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Your Cinematic Universe',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
