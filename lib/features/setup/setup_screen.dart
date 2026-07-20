import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:animate_do/animate_do.dart';
import 'package:aftercredits/core/theme/app_theme.dart';
import 'package:aftercredits/core/services/auth_service.dart';
import 'package:aftercredits/core/services/user_profile_service.dart';
import 'package:aftercredits/core/services/tmdb_service.dart';
import 'package:aftercredits/models/movie_model.dart';
import 'package:aftercredits/features/home/home_screen.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _pageController = PageController();
  int _step = 0;
  bool _isSaving = false;

  // ── Step data ─────────────────────────────────────────────
  final _usernameCtrl = TextEditingController();
  bool _usernameAvailable = false;
  bool _checkingUsername = false;
  String? _usernameError;
  Timer? _debounce;

  XFile? _avatarFile;

  final Set<int> _selectedGenres = {};
  final Set<int> _selectedMovies = {};

  List<MovieModel> _trendingMovies = [];
  bool _loadingMovies = true;

  // ── Services ──────────────────────────────────────────────
  final _auth = AuthService();
  final _profile = UserProfileService();
  final _tmdb = TmdbService();
  final _picker = ImagePicker();

  // ── Static genre data ─────────────────────────────────────
  static const List<Map<String, dynamic>> _genres = [
    {'id': 28, 'name': 'Aksi', 'emoji': '💥', 'color': 0xFFE50914},
    {'id': 18, 'name': 'Drama', 'emoji': '🎭', 'color': 0xFF7C3AED},
    {'id': 878, 'name': 'Sci-Fi', 'emoji': '🚀', 'color': 0xFF0EA5E9},
    {'id': 35, 'name': 'Komedi', 'emoji': '😂', 'color': 0xFFF59E0B},
    {'id': 53, 'name': 'Thriller', 'emoji': '😱', 'color': 0xFFFF6B35},
    {'id': 27, 'name': 'Horor', 'emoji': '👻', 'color': 0xFF6366F1},
    {'id': 10749, 'name': 'Romansa', 'emoji': '❤️', 'color': 0xFFEC4899},
    {'id': 16, 'name': 'Animasi', 'emoji': '🎨', 'color': 0xFF10B981},
    {'id': 99, 'name': 'Dokumenter', 'emoji': '📽️', 'color': 0xFF14B8A6},
    {'id': 80, 'name': 'Kriminal', 'emoji': '🔫', 'color': 0xFF8B5CF6},
    {'id': 12, 'name': 'Petualangan', 'emoji': '🗺️', 'color': 0xFF0EA5E9},
    {'id': 14, 'name': 'Fantasy', 'emoji': '🧙', 'color': 0xFFDB2777},
  ];

  @override
  void initState() {
    super.initState();
    _fetchMovies();
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _pageController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // ─── Data loading ─────────────────────────────────────────

  Future<void> _fetchMovies() async {
    final movies = await _tmdb.getTopRated();
    if (mounted) {
      setState(() {
        _trendingMovies = movies.take(24).toList();
        _loadingMovies = false;
      });
    }
  }

  // ─── Username validation ──────────────────────────────────

  void _onUsernameChanged(String value) {
    _debounce?.cancel();
    setState(() {
      _usernameAvailable = false;
      _usernameError = null;
    });

    if (value.trim().length < 3) {
      setState(() =>
          _usernameError = value.isEmpty ? null : 'Minimal 3 karakter');
      return;
    }

    final valid = RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value.trim());
    if (!valid) {
      setState(() =>
          _usernameError = 'Hanya huruf, angka, dan underscore (_)');
      return;
    }

    setState(() => _checkingUsername = true);
    _debounce = Timer(const Duration(milliseconds: 600), () async {
      final available = await _profile.isUsernameAvailable(value.trim());
      if (mounted) {
        setState(() {
          _usernameAvailable = available;
          _usernameError = available ? null : 'Username sudah digunakan';
          _checkingUsername = false;
        });
      }
    });
  }

  // ─── Avatar ───────────────────────────────────────────────

  Future<void> _pickAvatar() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (file != null && mounted) {
      setState(() => _avatarFile = file);
    }
  }

  // ─── Navigation ───────────────────────────────────────────

  bool get _canProceed {
    switch (_step) {
      case 0:
        return _usernameAvailable &&
            _usernameCtrl.text.trim().length >= 3 &&
            !_checkingUsername;
      case 1:
        return true; // avatar optional
      case 2:
        return _selectedGenres.length >= 3;
      case 3:
        return _selectedMovies.length >= 5;
      default:
        return false;
    }
  }

  void _next() {
    if (_step < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _save();
    }
  }

  // ─── Save profile ─────────────────────────────────────────

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final userId = _auth.currentUser!.id;
      String? avatarUrl;

      if (_avatarFile != null) {
        final bytes = await _avatarFile!.readAsBytes();
        final ext = _avatarFile!.name.split('.').last;
        avatarUrl = await _profile.uploadAvatar(
          userId: userId,
          bytes: bytes,
          extension: ext,
        );
      }

      await _profile.saveProfile(
        userId: userId,
        username: _usernameCtrl.text.trim(),
        avatarUrl: avatarUrl,
        favoriteGenreIds: _selectedGenres.toList(),
        favoriteMovieIds: _selectedMovies.toList(),
      );

      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, animation, __) => const HomeScreen(),
            transitionsBuilder: (_, animation, __, child) =>
                FadeTransition(opacity: animation, child: child),
            transitionDuration: const Duration(milliseconds: 600),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan: ${e.toString()}'),
            backgroundColor: AppColors.accentRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  // ─── Build ────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkPrimary,
      body: SafeArea(
        child: Column(
          children: [
            _buildProgressHeader(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _step = i),
                children: [
                  _buildUsernameStep(),
                  _buildAvatarStep(),
                  _buildGenresStep(),
                  _buildMoviesStep(),
                ],
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  // ─── Progress header ──────────────────────────────────────

  Widget _buildProgressHeader() {
    const stepLabels = ['Username', 'Foto Profil', 'Genre', 'Film Favorit'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 4),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Langkah ${_step + 1} dari 4',
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 12),
              ),
              // Skip avatar step
              if (_step == 1)
                TextButton(
                  onPressed: _next,
                  style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 36)),
                  child: const Text(
                    'Lewati',
                    style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w500),
                  ),
                )
              else
                const SizedBox(height: 36),
            ],
          ),
          const SizedBox(height: 8),
          // Progress bars
          Row(
            children: List.generate(4, (i) => Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                height: 3,
                margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
                decoration: BoxDecoration(
                  color: i <= _step ? AppColors.accentRed : AppColors.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            )),
          ),
          const SizedBox(height: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Align(
              key: ValueKey(_step),
              alignment: Alignment.centerLeft,
              child: Text(
                stepLabels[_step].toUpperCase(),
                style: const TextStyle(
                  color: AppColors.accentRed,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Step 1: Username ─────────────────────────────────────

  Widget _buildUsernameStep() {
    return FadeInUp(
      key: const ValueKey('step0'),
      duration: const Duration(milliseconds: 400),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pilih Username\nKamu 👤',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Username akan terlihat di profil dan komunitas.\nHanya bisa diubah di pengaturan nanti.',
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 32),
            TextFormField(
              controller: _usernameCtrl,
              autofocus: true,
              onChanged: _onUsernameChanged,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                hintText: 'cinephile_id',
                hintStyle: const TextStyle(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w400,
                    fontSize: 17),
                prefixText: '@',
                prefixStyle: const TextStyle(
                  color: AppColors.accentRed,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
                filled: true,
                fillColor: AppColors.darkTertiary,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: _usernameError != null
                        ? AppColors.accentRed
                        : _usernameAvailable
                            ? const Color(0xFF10B981)
                            : AppColors.border,
                    width: _usernameAvailable || _usernameError != null
                        ? 1.5
                        : 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: _usernameError != null
                        ? AppColors.accentRed
                        : _usernameAvailable
                            ? const Color(0xFF10B981)
                            : AppColors.accentRed,
                    width: 2,
                  ),
                ),
                suffixIcon: _checkingUsername
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.textMuted),
                        ),
                      )
                    : _usernameAvailable
                        ? const Icon(Icons.check_circle_rounded,
                            color: Color(0xFF10B981))
                        : _usernameError != null
                            ? const Icon(Icons.cancel_rounded,
                                color: AppColors.accentRed)
                            : null,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18, vertical: 18),
              ),
            ),
            const SizedBox(height: 10),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _usernameError != null
                  ? Row(
                      key: ValueKey(_usernameError),
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            color: AppColors.accentRed, size: 13),
                        const SizedBox(width: 6),
                        Text(_usernameError!,
                            style: const TextStyle(
                                color: AppColors.accentRed, fontSize: 12)),
                      ],
                    )
                  : _usernameAvailable
                      ? const Row(
                          key: ValueKey('ok'),
                          children: [
                            Icon(Icons.check_circle_outline_rounded,
                                color: Color(0xFF10B981), size: 13),
                            SizedBox(width: 6),
                            Text('Username tersedia!',
                                style: TextStyle(
                                    color: Color(0xFF10B981), fontSize: 12)),
                          ],
                        )
                      : const Text(
                          key: ValueKey('hint'),
                          'Minimal 3 karakter. Huruf, angka, dan _ diperbolehkan.',
                          style: TextStyle(
                              color: AppColors.textMuted, fontSize: 12),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Step 2: Avatar ───────────────────────────────────────

  Widget _buildAvatarStep() {
    final initial = _usernameCtrl.text.isNotEmpty
        ? _usernameCtrl.text[0].toUpperCase()
        : '?';

    return FadeInUp(
      key: const ValueKey('step1'),
      duration: const Duration(milliseconds: 400),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tambah Foto\nProfil 📸',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Foto profil membuat kamu lebih dikenal di komunitas.\nLangkah ini bisa dilewati.',
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 48),
            Center(
              child: GestureDetector(
                onTap: _pickAvatar,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.darkTertiary,
                        border: Border.all(
                            color: AppColors.accentRed, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accentRed.withOpacity(0.25),
                            blurRadius: 30,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: _avatarFile != null
                          ? ClipOval(
                              child: kIsWeb
                                  ? Image.network(
                                      _avatarFile!.path,
                                      fit: BoxFit.cover,
                                      width: 150,
                                      height: 150,
                                    )
                                  : Image.file(
                                      File(_avatarFile!.path),
                                      fit: BoxFit.cover,
                                      width: 150,
                                      height: 150,
                                    ),
                            )
                          : Center(
                              child: Text(
                                initial,
                                style: const TextStyle(
                                  fontSize: 60,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                    ),
                    // Camera button
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.accentRed,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: AppColors.darkPrimary, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accentRed.withOpacity(0.4),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.camera_alt_rounded,
                          color: Colors.white, size: 20),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Column(
                children: [
                  TextButton.icon(
                    onPressed: _pickAvatar,
                    icon: const Icon(Icons.photo_library_rounded,
                        size: 16, color: AppColors.accentRed),
                    label: const Text(
                      'Pilih dari Galeri',
                      style: TextStyle(
                        color: AppColors.accentRed,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (_avatarFile != null)
                    TextButton(
                      onPressed: () =>
                          setState(() => _avatarFile = null),
                      child: const Text(
                        'Hapus Foto',
                        style: TextStyle(
                            color: AppColors.textMuted, fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Step 3: Genres ───────────────────────────────────────

  Widget _buildGenresStep() {
    return FadeInUp(
      key: const ValueKey('step2'),
      duration: const Duration(milliseconds: 400),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Genre Favorit\nKamu 🎬',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 8),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 250),
              style: TextStyle(
                color: _selectedGenres.length >= 3
                    ? const Color(0xFF10B981)
                    : AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              child: Text(
                _selectedGenres.length >= 3
                    ? '✓ ${_selectedGenres.length} genre dipilih'
                    : 'Pilih minimal 3 genre • ${_selectedGenres.length}/3',
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.builder(
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.95,
                ),
                itemCount: _genres.length,
                itemBuilder: (_, i) {
                  final g = _genres[i];
                  final id = g['id'] as int;
                  final selected = _selectedGenres.contains(id);
                  final color = Color(g['color'] as int);
                  return GestureDetector(
                    onTap: () => setState(() {
                      if (selected) _selectedGenres.remove(id);
                      else _selectedGenres.add(id);
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: selected
                            ? color.withOpacity(0.18)
                            : AppColors.darkTertiary,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selected ? color : AppColors.border,
                          width: selected ? 2 : 1,
                        ),
                        boxShadow: selected
                            ? [
                                BoxShadow(
                                  color: color.withOpacity(0.2),
                                  blurRadius: 12,
                                ),
                              ]
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(g['emoji'] as String,
                              style: const TextStyle(fontSize: 30)),
                          const SizedBox(height: 6),
                          Text(
                            g['name'] as String,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: selected
                                  ? color
                                  : AppColors.textSecondary,
                              fontSize: 11,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                          if (selected)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Icon(Icons.check_circle_rounded,
                                  color: color, size: 12),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Step 4: Favorite Movies ──────────────────────────────

  Widget _buildMoviesStep() {
    return FadeInUp(
      key: const ValueKey('step3'),
      duration: const Duration(milliseconds: 400),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Film Favorit\nKamu 🍿',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 8),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 250),
              style: TextStyle(
                color: _selectedMovies.length >= 5
                    ? const Color(0xFF10B981)
                    : AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              child: Text(
                _selectedMovies.length >= 5
                    ? '✓ ${_selectedMovies.length} film dipilih'
                    : 'Pilih minimal 5 film • ${_selectedMovies.length}/5',
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _loadingMovies
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.accentRed),
                    )
                  : GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 0.65,
                      ),
                      itemCount: _trendingMovies.length,
                      itemBuilder: (_, i) {
                        final movie = _trendingMovies[i];
                        final selected =
                            _selectedMovies.contains(movie.id);
                        return GestureDetector(
                          onTap: () => setState(() {
                            if (selected) _selectedMovies.remove(movie.id);
                            else _selectedMovies.add(movie.id);
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: selected
                                    ? AppColors.accentRed
                                    : Colors.transparent,
                                width: 2.5,
                              ),
                              boxShadow: selected
                                  ? [
                                      BoxShadow(
                                        color: AppColors.accentRed
                                            .withOpacity(0.4),
                                        blurRadius: 10,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: movie.posterUrl != null
                                      ? Image.network(
                                          movie.posterUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              Container(
                                            color: AppColors.darkTertiary,
                                            child: const Icon(Icons.movie,
                                                color: AppColors.textMuted),
                                          ),
                                        )
                                      : Container(
                                          color: AppColors.darkTertiary),
                                ),
                                if (selected)
                                  ClipRRect(
                                    borderRadius:
                                        BorderRadius.circular(8),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            AppColors.accentRed
                                                .withOpacity(0.5),
                                            AppColors.accentRed
                                                .withOpacity(0.25),
                                          ],
                                        ),
                                      ),
                                      child: const Center(
                                        child: Icon(
                                          Icons.check_circle_rounded,
                                          color: Colors.white,
                                          size: 38,
                                          shadows: [
                                            Shadow(
                                              color: Colors.black38,
                                              blurRadius: 8,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Bottom action bar ────────────────────────────────────

  Widget _buildBottomBar() {
    const labels = ['Lanjut', 'Lanjut', 'Lanjut', 'Mulai!'];
    const icons = [
      Icons.arrow_forward_rounded,
      Icons.arrow_forward_rounded,
      Icons.arrow_forward_rounded,
      Icons.rocket_launch_rounded,
    ];

    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: const BoxDecoration(
        color: AppColors.darkPrimary,
        border: Border(
            top: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 54,
        child: ElevatedButton.icon(
          onPressed: _canProceed && !_isSaving ? _next : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accentRed,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            disabledBackgroundColor: AppColors.accentRed.withOpacity(0.25),
          ),
          icon: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Icon(icons[_step], size: 18),
          label: Text(
            _isSaving ? 'Menyimpan...' : labels[_step],
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
