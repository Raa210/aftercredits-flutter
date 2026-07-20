import 'package:flutter/material.dart';
import 'package:aftercredits/features/home/tabs/community/community_colors.dart';

/// Header responsif Community page.
///
/// Desktop: 3 bagian sejajar (Judul | Search | Tombol).
/// Mobile:  Stack vertikal.
class CommunityHeader extends StatelessWidget {
  final VoidCallback? onCreateThread;
  final ValueChanged<String>? onSearch;

  const CommunityHeader({
    super.key,
    this.onCreateThread,
    this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 768;

    if (isDesktop) {
      return _buildDesktopHeader();
    }
    return _buildMobileHeader();
  }

  Widget _buildDesktopHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        CommunitySpacing.lg,
        CommunitySpacing.lg,
        CommunitySpacing.lg,
        CommunitySpacing.md,
      ),
      child: Row(
        children: [
          // ─── Kiri: Judul + Subtitle ──────────────────
          Expanded(
            flex: 3,
            child: _buildTitle(),
          ),
          const SizedBox(width: CommunitySpacing.lg),

          // ─── Tengah: Search Bar ──────────────────────
          Expanded(
            flex: 4,
            child: _buildSearchBar(),
          ),
          const SizedBox(width: CommunitySpacing.lg),

          // ─── Kanan: Tombol Buat Thread ───────────────
          _buildCreateButton(),
        ],
      ),
    );
  }

  Widget _buildMobileHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        CommunitySpacing.md,
        CommunitySpacing.md,
        CommunitySpacing.md,
        CommunitySpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Judul + Tombol pada satu baris
          Row(
            children: [
              Expanded(child: _buildTitle()),
              const SizedBox(width: CommunitySpacing.md),
              _buildCreateButton(),
            ],
          ),
          const SizedBox(height: CommunitySpacing.md),
          _buildSearchBar(),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: CommunityColors.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(CommunityRadius.sm),
              ),
              child: const Icon(
                Icons.forum_rounded,
                color: CommunityColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: CommunitySpacing.sm),
            const Text(
              'Community',
              style: TextStyle(
                color: CommunityColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: CommunitySpacing.xs),
        const Padding(
          padding: EdgeInsets.only(left: 44),
          child: Text(
            'Temukan teori, ending, dan diskusi film favoritmu.',
            style: TextStyle(
              color: CommunityColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w400,
              height: 1.4,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: CommunityColors.searchBar,
        borderRadius: BorderRadius.circular(CommunityRadius.pill),
        border: Border.all(
          color: CommunityColors.searchBarBorder,
          width: 1,
        ),
      ),
      child: TextField(
        onChanged: onSearch,
        style: const TextStyle(
          color: CommunityColors.textPrimary,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          hintText: 'Cari diskusi...',
          hintStyle: const TextStyle(
            color: CommunityColors.textMuted,
            fontSize: 14,
          ),
          prefixIcon: const Padding(
            padding: EdgeInsets.only(left: 16, right: 8),
            child: Icon(
              Icons.search_rounded,
              color: CommunityColors.textMuted,
              size: 20,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 44,
            minHeight: 44,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: CommunitySpacing.md,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildCreateButton() {
    return SizedBox(
      height: 50,
      child: ElevatedButton.icon(
        onPressed: onCreateThread ?? () {},
        icon: const Icon(Icons.add_rounded, size: 20),
        label: const Text('Buat Thread'),
        style: ElevatedButton.styleFrom(
          backgroundColor: CommunityColors.primary,
          foregroundColor: CommunityColors.textPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(CommunityRadius.pill),
          ),
        ),
      ),
    );
  }
}
