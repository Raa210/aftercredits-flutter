import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/auth_service.dart';
import '../../auth/login_screen.dart';

/// Halaman Pengaturan — dibuka dari tombol ⚙️ di header profil.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    final isGuest = user == null;

    return Scaffold(
      backgroundColor: AppColors.darkPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.darkPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Pengaturan',
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
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          // ── Akun ──────────────────────────────────────────
          _SectionHeader(label: 'AKUN'),
          _SettingsTile(
            icon: Icons.person_outline_rounded,
            iconColor: const Color(0xFF0EA5E9),
            label: 'Edit Profil',
            subtitle: 'Ubah username dan foto profil',
            onTap: () => _showComingSoon(context, 'Edit Profil'),
          ),
          _SettingsTile(
            icon: Icons.bookmark_border_rounded,
            iconColor: const Color(0xFF7C3AED),
            label: 'Watchlist',
            subtitle: 'Kelola daftar film yang ingin ditonton',
            onTap: () => _showComingSoon(context, 'Watchlist'),
          ),
          _SettingsTile(
            icon: Icons.movie_filter_outlined,
            iconColor: const Color(0xFFF59E0B),
            label: 'Selera Film',
            subtitle: 'Perbarui genre dan film favorit kamu',
            onTap: () => _showComingSoon(context, 'Selera Film'),
          ),

          const SizedBox(height: 24),

          // ── Preferensi ────────────────────────────────────
          _SectionHeader(label: 'PREFERENSI'),
          _SettingsTile(
            icon: Icons.notifications_outlined,
            iconColor: const Color(0xFF10B981),
            label: 'Notifikasi',
            subtitle: 'Atur notifikasi film & komunitas',
            onTap: () => _showComingSoon(context, 'Notifikasi'),
          ),
          _SettingsTile(
            icon: Icons.palette_outlined,
            iconColor: const Color(0xFFEC4899),
            label: 'Tampilan',
            subtitle: 'Tema dan preferensi tampilan',
            onTap: () => _showComingSoon(context, 'Tampilan'),
          ),
          _SettingsTile(
            icon: Icons.language_outlined,
            iconColor: const Color(0xFF0EA5E9),
            label: 'Bahasa',
            subtitle: 'Bahasa antarmuka aplikasi',
            onTap: () => _showComingSoon(context, 'Bahasa'),
          ),

          const SizedBox(height: 24),

          // ── Privasi & Keamanan ────────────────────────────
          _SectionHeader(label: 'PRIVASI & KEAMANAN'),
          _SettingsTile(
            icon: Icons.lock_outline_rounded,
            iconColor: AppColors.accentRed,
            label: 'Privasi',
            subtitle: 'Kontrol visibilitas profil kamu',
            onTap: () => _showComingSoon(context, 'Privasi'),
          ),
          _SettingsTile(
            icon: Icons.shield_outlined,
            iconColor: const Color(0xFF7C3AED),
            label: 'Keamanan',
            subtitle: 'Kelola keamanan akun',
            onTap: () => _showComingSoon(context, 'Keamanan'),
          ),

          const SizedBox(height: 24),

          // ── Lainnya ───────────────────────────────────────
          _SectionHeader(label: 'LAINNYA'),
          _SettingsTile(
            icon: Icons.help_outline_rounded,
            iconColor: const Color(0xFFF59E0B),
            label: 'Bantuan & FAQ',
            subtitle: 'Pertanyaan umum dan dukungan',
            onTap: () => _showComingSoon(context, 'Bantuan & FAQ'),
          ),
          _SettingsTile(
            icon: Icons.info_outline_rounded,
            iconColor: const Color(0xFF0EA5E9),
            label: 'Tentang AfterCredits',
            subtitle: 'Versi 1.0.0 · Built with ❤️',
            onTap: () => _showAboutDialog(context),
          ),
          _SettingsTile(
            icon: Icons.star_outline_rounded,
            iconColor: AppColors.star,
            label: 'Beri Rating Aplikasi',
            subtitle: 'Bantu kami berkembang dengan rating kamu',
            onTap: () => _showComingSoon(context, 'Rating'),
          ),

          // ── Keluar (hanya jika login) ──────────────────────
          if (!isGuest) ...[
            const SizedBox(height: 24),
            const Divider(color: AppColors.border, thickness: 0.5),
            const SizedBox(height: 8),
            _SettingsTile(
              icon: Icons.logout_rounded,
              iconColor: AppColors.accentRed,
              label: 'Keluar',
              subtitle: 'Logout dari akun AfterCredits',
              labelColor: AppColors.accentRed,
              showChevron: false,
              onTap: () => _confirmSignOut(context),
            ),
          ],

          const SizedBox(height: 48),

          // ── Footer ────────────────────────────────────────
          Center(
            child: Column(
              children: [
                const Icon(Icons.movie_creation_outlined,
                    color: AppColors.textMuted, size: 22),
                const SizedBox(height: 6),
                const Text(
                  'AfterCredits',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Versi 1.0.0',
                  style: TextStyle(
                    color: AppColors.textMuted.withOpacity(0.6),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature — Segera hadir!'),
        backgroundColor: AppColors.darkSecondary,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkSecondary,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.movie_creation_outlined,
                color: AppColors.accentRed, size: 24),
            SizedBox(width: 10),
            Text(
              'AfterCredits',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Versi 1.0.0',
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 13)),
            SizedBox(height: 8),
            Text(
              'Temukan, tonton, dan diskusikan film\nbersama komunitasmu.',
              style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.5),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup',
                style: TextStyle(color: AppColors.accentRed)),
          ),
        ],
      ),
    );
  }

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkSecondary,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Keluar?',
          style: TextStyle(
              color: AppColors.textPrimary, fontWeight: FontWeight.w800),
        ),
        content: const Text(
          'Kamu akan keluar dari akun AfterCredits.',
          style:
              TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await AuthService().signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                      builder: (_) => const AuthScreen()),
                  (_) => false,
                );
              }
            },
            child: const Text(
              'Keluar',
              style: TextStyle(
                  color: AppColors.accentRed,
                  fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Section header widget
// ─────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Settings tile widget
// ─────────────────────────────────────────────────────────

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String? subtitle;
  final Color? labelColor;
  final bool showChevron;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
    this.subtitle,
    this.labelColor,
    this.showChevron = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: AppColors.darkSecondary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 19, color: iconColor),
        ),
        title: Text(
          label,
          style: TextStyle(
            color: labelColor ?? AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  height: 1.4,
                ),
              )
            : null,
        trailing: showChevron
            ? const Icon(Icons.chevron_right_rounded,
                color: AppColors.textMuted, size: 18)
            : null,
        onTap: onTap,
      ),
    );
  }
}
