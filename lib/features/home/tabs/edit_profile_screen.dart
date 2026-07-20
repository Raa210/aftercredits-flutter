import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:aftercredits/core/theme/app_theme.dart';
import 'package:aftercredits/core/services/auth_service.dart';
import 'package:aftercredits/core/services/user_profile_service.dart';
import 'package:aftercredits/models/user_profile_model.dart';

/// Halaman untuk mengubah foto profil, username, dan bio pengguna.
class EditProfileScreen extends StatefulWidget {
  final UserProfileModel? initialProfile;

  const EditProfileScreen({super.key, this.initialProfile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _usernameController;
  late TextEditingController _bioController;

  Uint8List? _pickedImageBytes;
  String? _pickedImageExtension;
  bool _loading = false;
  String? _errorMessage;

  UserProfileModel? _profile;

  @override
  void initState() {
    super.initState();
    _profile = widget.initialProfile;
    _usernameController = TextEditingController(
      text: _profile?.username ?? '',
    );
    _bioController = TextEditingController(
      text: _profile?.bio ?? '',
    );
    if (_profile == null) {
      _loadCurrentProfile();
    }
  }

  Future<void> _loadCurrentProfile() async {
    final user = AuthService().currentUser;
    if (user == null) return;
    final p = await UserProfileService().getProfile(user.id);
    if (p != null && mounted) {
      setState(() {
        _profile = p;
        if (_usernameController.text.isEmpty) {
          _usernameController.text = p.username;
        }
        if (_bioController.text.isEmpty) {
          _bioController.text = p.bio ?? '';
        }
      });
    }
  }


  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (picked != null) {
        final bytes = await picked.readAsBytes();
        final ext = picked.name.split('.').last.toLowerCase();
        setState(() {
          _pickedImageBytes = bytes;
          _pickedImageExtension = ext.isNotEmpty ? ext : 'jpg';
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal memilih gambar. Pastikan izin galeri diberikan.';
      });
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    final user = AuthService().currentUser;
    if (user == null) return;

    final newUsername = _usernameController.text.trim().toLowerCase();
    final newBio = _bioController.text.trim();

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      // Jika username berubah, periksa ketersediaan
      if (newUsername != _profile?.username) {
        final available = await UserProfileService().isUsernameAvailable(newUsername);
        if (!available) {
          setState(() {
            _errorMessage = 'Username @$newUsername sudah digunakan oleh orang lain.';
            _loading = false;
          });
          return;
        }
      }

      String? avatarUrl = _profile?.avatarUrl;

      // Unggah foto profil baru jika ada yang dipilih
      if (_pickedImageBytes != null && _pickedImageExtension != null) {
        avatarUrl = await UserProfileService().uploadAvatar(
          userId: user.id,
          bytes: _pickedImageBytes!,
          extension: _pickedImageExtension!,
        );
      }

      // Simpan perubahan ke tabel profiles
      await UserProfileService().updateProfile(
        userId: user.id,
        username: newUsername,
        bio: newBio,
        avatarUrl: avatarUrl,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profil berhasil diperbarui!'),
            backgroundColor: AppColors.accentRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentAvatarUrl = _profile?.avatarUrl;

    return Scaffold(
      backgroundColor: AppColors.darkPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.darkPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Edit Profil',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 0.5),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Avatar preview + pick button ────────────────────
              GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.accentRed, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accentRed.withValues(alpha: 0.25),
                            blurRadius: 16,
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 54,
                        backgroundColor: AppColors.darkTertiary,
                        backgroundImage: _pickedImageBytes != null
                            ? MemoryImage(_pickedImageBytes!) as ImageProvider
                            : (currentAvatarUrl != null ? NetworkImage(currentAvatarUrl) : null),
                        child: (_pickedImageBytes == null && currentAvatarUrl == null)
                            ? const Icon(Icons.person_outline_rounded, size: 50, color: AppColors.textMuted)
                            : null,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.accentRed,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.darkPrimary, width: 3),
                      ),
                      child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: _pickImage,
                child: const Text(
                  'Ubah Foto Profil',
                  style: TextStyle(
                    color: AppColors.accentRed,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              if (_errorMessage != null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.accentRed.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.accentRed.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: AppColors.accentRed, fontSize: 13),
                  ),
                ),

              // ── Username field ──────────────────────────────────
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Username',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _usernameController,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
                decoration: InputDecoration(
                  prefixText: '@ ',
                  prefixStyle: const TextStyle(color: AppColors.textMuted, fontSize: 15, fontWeight: FontWeight.bold),
                  hintText: 'username',
                  hintStyle: const TextStyle(color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.darkSecondary,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border, width: 0.5),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border, width: 0.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.accentRed, width: 1.5),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Username tidak boleh kosong';
                  }
                  if (val.trim().length < 3) {
                    return 'Username minimal 3 karakter';
                  }
                  if (!RegExp(r'^[a-zA-Z0-9_.]+$').hasMatch(val.trim())) {
                    return 'Hanya huruf, angka, titik, dan underscore';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // ── Bio field ───────────────────────────────────────
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Bio',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _bioController,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
                maxLines: 4,
                maxLength: 160,
                decoration: InputDecoration(
                  hintText: 'Tulis sedikit tentang dirimu atau film favoritmu...',
                  hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                  filled: true,
                  fillColor: AppColors.darkSecondary,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border, width: 0.5),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border, width: 0.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.accentRed, width: 1.5),
                  ),
                ),
              ),

              const SizedBox(height: 36),

              // ── Save Button ─────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentRed,
                    disabledBackgroundColor: AppColors.accentRed.withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                        )
                      : const Text(
                          'Simpan Perubahan',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
