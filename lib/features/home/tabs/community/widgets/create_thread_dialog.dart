import 'dart:async';
import 'package:flutter/material.dart';
import 'package:aftercredits/core/theme/app_theme.dart';
import 'package:aftercredits/core/services/tmdb_service.dart';
import 'package:aftercredits/core/services/community_service.dart';
import 'package:aftercredits/models/movie_model.dart';
import 'package:aftercredits/features/home/tabs/community/community_colors.dart';

class CreateThreadDialog extends StatefulWidget {
  final VoidCallback onSuccess;

  const CreateThreadDialog({super.key, required this.onSuccess});

  @override
  State<CreateThreadDialog> createState() => _CreateThreadDialogState();
}

class _CreateThreadDialogState extends State<CreateThreadDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _searchMovieController = TextEditingController();

  String _selectedTag = 'DISKUSI';
  MovieModel? _selectedMovie;
  List<MovieModel> _searchedMovies = [];
  bool _searchingMovies = false;
  bool _submitting = false;
  Timer? _debounce;

  final Map<String, int> _tagColors = {
    'ENDING': 0xFFE50914,
    'TEORI': 0xFF7C3AED,
    'SPOILER': 0xFFFF6B35,
    'DISKUSI': 0xFF0EA5E9,
  };

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _searchMovieController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchMovieChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.trim().isEmpty) {
        setState(() {
          _searchedMovies = [];
          _searchingMovies = false;
        });
        return;
      }
      setState(() => _searchingMovies = true);
      try {
        final results = await TmdbService().searchMovies(query.trim());
        setState(() {
          _searchedMovies = results;
          _searchingMovies = false;
        });
      } catch (_) {
        setState(() => _searchingMovies = false);
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    try {
      final tagColor = _tagColors[_selectedTag] ?? 0xFFE50914;

      await CommunityService().createThread(
        title: _titleController.text.trim(),
        preview: _contentController.text.trim(),
        tag: _selectedTag,
        tagColor: tagColor,
        movieId: _selectedMovie?.id,
        movieTitle: _selectedMovie?.title,
        posterUrl: _selectedMovie?.posterUrl,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thread berhasil dibuat!'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onSuccess();
      }
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
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: CommunityColors.card,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(CommunityRadius.lg),
        side: const BorderSide(color: CommunityColors.divider, width: 0.5),
      ),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Dialog
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Buat Thread Baru',
                      style: TextStyle(
                        color: CommunityColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded,
                          color: CommunityColors.textMuted),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Pilih Kategori/Tag
                const Text(
                  'Kategori',
                  style: TextStyle(
                    color: CommunityColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: _tagColors.keys.map((tag) {
                    final isSelected = _selectedTag == tag;
                    final color = Color(_tagColors[tag]!);

                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: ChoiceChip(
                          showCheckmark: false,
                          label: Text(
                            tag,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: isSelected
                                  ? Colors.white
                                  : CommunityColors.textSecondary,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: color,
                          backgroundColor: CommunityColors.chipInactive,
                          side: BorderSide(
                            color: isSelected ? color : CommunityColors.divider,
                            width: 0.5,
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedTag = tag);
                            }
                          },
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Form Judul
                TextFormField(
                  controller: _titleController,
                  style: const TextStyle(color: CommunityColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Judul Thread',
                    hintText: 'Masukkan judul diskusi film...',
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Judul tidak boleh kosong';
                    }
                    if (val.trim().length < 5) {
                      return 'Judul minimal 5 karakter';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Form Isi Konten
                TextFormField(
                  controller: _contentController,
                  maxLines: 4,
                  style: const TextStyle(color: CommunityColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Isi Konten / Deskripsi',
                    hintText: 'Tulis detail teori, review, diskusi, atau spoiler film...',
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Konten tidak boleh kosong';
                    }
                    if (val.trim().length < 10) {
                      return 'Konten minimal 10 karakter';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Tambahkan Rujukan Film (Opsional)
                const Text(
                  'Hubungkan dengan Film (Opsional)',
                  style: TextStyle(
                    color: CommunityColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),

                if (_selectedMovie != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: CommunityColors.searchBar,
                      borderRadius: BorderRadius.circular(CommunityRadius.md),
                      border: Border.all(
                        color: CommunityColors.divider,
                        width: 0.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        if (_selectedMovie!.posterUrl != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.network(
                              _selectedMovie!.posterUrl!,
                              width: 32,
                              height: 48,
                              fit: BoxFit.cover,
                            ),
                          ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedMovie!.title,
                                style: const TextStyle(
                                  color: CommunityColors.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                _selectedMovie!.year,
                                style: const TextStyle(
                                  color: CommunityColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded,
                              color: CommunityColors.primary),
                          onPressed: () {
                            setState(() => _selectedMovie = null);
                          },
                        ),
                      ],
                    ),
                  )
                else ...[
                  // Search box film
                  TextField(
                    controller: _searchMovieController,
                    onChanged: _onSearchMovieChanged,
                    style: const TextStyle(color: CommunityColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Cari Film...',
                      prefixIcon: const Icon(Icons.movie_rounded,
                          color: CommunityColors.textMuted),
                      suffixIcon: _searchingMovies
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: Padding(
                                padding: EdgeInsets.all(12.0),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      CommunityColors.primary),
                                ),
                              ),
                            )
                          : null,
                    ),
                  ),

                  if (_searchedMovies.isNotEmpty)
                    Container(
                      height: 150,
                      margin: const EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        color: CommunityColors.searchBar,
                        borderRadius: BorderRadius.circular(CommunityRadius.md),
                        border: Border.all(
                          color: CommunityColors.divider,
                          width: 0.5,
                        ),
                      ),
                      child: ListView.builder(
                        itemCount: _searchedMovies.length,
                        itemBuilder: (context, index) {
                          final m = _searchedMovies[index];
                          return ListTile(
                            dense: true,
                            leading: m.posterUrl != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: Image.network(
                                      m.posterUrl!,
                                      width: 24,
                                      height: 36,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : const Icon(Icons.movie_creation_outlined),
                            title: Text(
                              m.title,
                              style: const TextStyle(
                                  color: CommunityColors.textPrimary),
                            ),
                            subtitle: Text(
                              m.year,
                              style: const TextStyle(
                                  color: CommunityColors.textSecondary),
                            ),
                            onTap: () {
                              setState(() {
                                _selectedMovie = m;
                                _searchedMovies = [];
                                _searchMovieController.clear();
                              });
                            },
                          );
                        },
                      ),
                    ),
                ],

                const SizedBox(height: 24),

                // Button Submit
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CommunityColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(CommunityRadius.md),
                      ),
                    ),
                    child: _submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Kirim Diskusi',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
