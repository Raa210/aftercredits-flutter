import 'package:flutter/material.dart';

/// Design tokens khusus untuk Community page.
/// Mengikuti spesifikasi dark-mode Netflix/Reddit/Letterboxd.
class CommunityColors {
  CommunityColors._();

  // ─── Background ──────────────────────────────────────────
  static const Color background = Color(0xFF111111);
  static const Color card = Color(0xFF1B1B1B);
  static const Color cardHover = Color(0xFF222222);

  // ─── Primary ─────────────────────────────────────────────
  static const Color primary = Color(0xFFE50914);
  static const Color primaryHover = Color(0xFFFF1A25);

  // ─── Text ────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFA0A0A0);
  static const Color textMuted = Color(0xFF666666);

  // ─── UI ──────────────────────────────────────────────────
  static const Color divider = Color(0xFF2A2A2A);
  static const Color chipInactive = Color(0xFF2A2A2A);
  static const Color chipInactiveText = Color(0xFF999999);
  static const Color searchBar = Color(0xFF1E1E1E);
  static const Color searchBarBorder = Color(0xFF333333);

  // ─── Tag Colors ──────────────────────────────────────────
  static const Color tagEnding = Color(0xFFE50914);
  static const Color tagSpoiler = Color(0xFFFF6B35);
  static const Color tagTeori = Color(0xFF7C3AED);
  static const Color tagDiskusi = Color(0xFF0EA5E9);
}

/// Spacing constants menggunakan 8-point grid system.
class CommunitySpacing {
  CommunitySpacing._();

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

/// Border radius constants.
class CommunityRadius {
  CommunityRadius._();

  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 18.0;
  static const double xl = 24.0;
  static const double pill = 100.0;
}
