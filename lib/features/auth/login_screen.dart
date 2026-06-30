import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/auth_service.dart';
import '../home/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  final _authService = AuthService();

  // Background poster for cinematic feel
  final String _backdropUrl =
      'https://image.tmdb.org/t/p/original/8Gxv8gSFCU0XGDykEGv7zR1n2ua.jpg';

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await _authService.signInWithGoogle();
      if (user != null && mounted) {
        _navigateToHome();
      } else if (mounted) {
        setState(() {
          _errorMessage = 'Sign in dibatalkan. Coba lagi.';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Terjadi kesalahan. Pastikan koneksi internet aktif.';
          _isLoading = false;
        });
      }
    }
  }

  void _continueAsGuest() {
    _navigateToHome();
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => const HomeScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.darkPrimary,
      body: Stack(
        children: [
          // ── Cinematic background ──────────────────────────
          Positioned.fill(
            child: Image.network(
              _backdropUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: AppColors.darkPrimary,
              ),
            ),
          ),

          // Dark gradient overlays
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x99000000),
                    Color(0xDD000000),
                    Color(0xFF0D0D0D),
                    Color(0xFF0D0D0D),
                  ],
                  stops: [0.0, 0.35, 0.6, 1.0],
                ),
              ),
            ),
          ),

          // Red radial glow
          Positioned(
            top: size.height * 0.3,
            left: -80,
            right: -80,
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    AppColors.accentRed.withOpacity(0.18),
                    Colors.transparent,
                  ],
                  radius: 0.8,
                ),
              ),
            ),
          ),

          // ── Content ──────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(height: size.height * 0.12),

                          // Logo & Branding
                          FadeInDown(
                            duration: const Duration(milliseconds: 700),
                            child: Column(
                              children: [
                                // Logo icon
                                Container(
                                  width: 72,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        AppColors.accentRed,
                                        AppColors.accentOrange,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.accentRed
                                            .withOpacity(0.45),
                                        blurRadius: 32,
                                        offset: const Offset(0, 12),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.movie_creation_rounded,
                                    color: Colors.white,
                                    size: 36,
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // App name
                                const Text(
                                  'AfterCredits',
                                  style: TextStyle(
                                    fontSize: 34,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.textPrimary,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Your Cinematic Universe',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.textSecondary,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: size.height * 0.07),

                          // Feature chips
                          FadeInUp(
                            delay: const Duration(milliseconds: 200),
                            duration: const Duration(milliseconds: 600),
                            child: Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              alignment: WrapAlignment.center,
                              children: const [
                                _FeatureChip(
                                  icon: Icons.auto_awesome_rounded,
                                  label: 'Discover',
                                ),
                                _FeatureChip(
                                  icon: Icons.forum_rounded,
                                  label: 'Community',
                                ),
                                _FeatureChip(
                                  icon: Icons.star_rounded,
                                  label: 'Reviews',
                                ),
                                _FeatureChip(
                                  icon: Icons.pie_chart_rounded,
                                  label: 'Taste Profile',
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: size.height * 0.06),

                          // Sign-in card
                          FadeInUp(
                            delay: const Duration(milliseconds: 350),
                            duration: const Duration(milliseconds: 600),
                            child: _SignInCard(
                              isLoading: _isLoading,
                              errorMessage: _errorMessage,
                              onGoogleSignIn: _signInWithGoogle,
                              onGuestContinue: _continueAsGuest,
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Privacy notice
                          FadeInUp(
                            delay: const Duration(milliseconds: 500),
                            duration: const Duration(milliseconds: 600),
                            child: const Text(
                              'Dengan masuk, kamu menyetujui Syarat & Ketentuan\ndan Kebijakan Privasi kami.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 11,
                                height: 1.6,
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Feature chip
// ─────────────────────────────────────────────────────────

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeatureChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Sign-in card
// ─────────────────────────────────────────────────────────

class _SignInCard extends StatelessWidget {
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onGoogleSignIn;
  final VoidCallback onGuestContinue;

  const _SignInCard({
    required this.isLoading,
    required this.errorMessage,
    required this.onGoogleSignIn,
    required this.onGuestContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.darkSecondary.withOpacity(0.85),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Masuk untuk memulai',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Simpan film favorit, tulis review, dan\nbergabung dengan komunitas cinephile',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 24),

          // Error message
          if (errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.accentRed.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppColors.accentRed.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_rounded,
                      color: AppColors.accentRed, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      errorMessage!,
                      style: const TextStyle(
                        color: AppColors.accentRed,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Google Sign-in button
          _GoogleSignInButton(
            isLoading: isLoading,
            onPressed: onGoogleSignIn,
          ),

          const SizedBox(height: 16),

          // Divider
          Row(
            children: [
              const Expanded(
                child: Divider(color: AppColors.border, thickness: 0.5),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'atau',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ),
              const Expanded(
                child: Divider(color: AppColors.border, thickness: 0.5),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Guest button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              onPressed: isLoading ? null : onGuestContinue,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(
                    color: AppColors.border, width: 1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                foregroundColor: AppColors.textSecondary,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_outline_rounded, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Lanjutkan sebagai Tamu',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Google sign-in button
// ─────────────────────────────────────────────────────────

class _GoogleSignInButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const _GoogleSignInButton({
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1F1F1F),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          disabledBackgroundColor: Colors.white.withOpacity(0.6),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppColors.accentRed),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Google logo
                  _GoogleLogo(),
                  const SizedBox(width: 12),
                  const Text(
                    'Masuk dengan Google',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F1F1F),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _GoogleLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 22,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;
    final double r = size.width / 2;

    // Clip to circle
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r)));

    // Draw Google 'G' segments (simplified colored arcs)
    final colors = [
      const Color(0xFF4285F4), // blue
      const Color(0xFF34A853), // green
      const Color(0xFFFBBC05), // yellow
      const Color(0xFFEA4335), // red
    ];
    final starts = [-0.52, 0.52, 1.05, -1.60];
    final sweeps = [1.04, 0.53, 0.55, 1.08];

    for (int i = 0; i < 4; i++) {
      final paint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.38;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.62),
        starts[i] * 3.14159,
        sweeps[i] * 3.14159,
        false,
        paint,
      );
    }

    // White center gap to simulate the 'G' cutout
    canvas.drawRect(
      Rect.fromLTWH(cx - 0.5, cy - r * 0.4, r, r * 0.4),
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
