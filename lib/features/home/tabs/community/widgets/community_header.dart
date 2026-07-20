import 'package:flutter/material.dart';
import 'package:aftercredits/core/theme/app_theme.dart';
import 'package:aftercredits/features/home/tabs/community/community_colors.dart';

/// Header responsif Community page.
///
/// Desktop: 3 bagian sejajar (Judul | Search | Tombol).
/// Mobile:  Stack vertikal.
class CommunityHeader extends StatefulWidget {
  final VoidCallback? onCreateThread;
  final ValueChanged<String>? onSearch;

  const CommunityHeader({
    super.key,
    this.onCreateThread,
    this.onSearch,
  });

  @override
  State<CommunityHeader> createState() => _CommunityHeaderState();
}

class _CommunityHeaderState extends State<CommunityHeader> {
  final TextEditingController _controller = TextEditingController();
  bool _hasQuery = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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
              const SizedBox(width: CommunitySpacing.sm),
              Flexible(child: _buildCreateButton()),
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
            const Flexible(
              child: Text(
                'Community',
                style: TextStyle(
                  color: CommunityColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),

      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.darkTertiary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(
            Icons.search_rounded,
            color: AppColors.textMuted,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _controller,
              onChanged: (val) {
                setState(() => _hasQuery = val.isNotEmpty);
                widget.onSearch?.call(val);
              },
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              decoration: const InputDecoration(
                isDense: true,
                hintText: 'Cari diskusi atau pengguna...',
                hintStyle: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (_hasQuery) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                _controller.clear();
                setState(() => _hasQuery = false);
                widget.onSearch?.call('');
              },
              behavior: HitTestBehavior.opaque,
              child: const Padding(
                padding: EdgeInsets.all(4.0),
                child: Icon(
                  Icons.close_rounded,
                  color: AppColors.textMuted,
                  size: 18,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCreateButton() {
    return SizedBox(
      height: 48,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: ElevatedButton.icon(
          onPressed: widget.onCreateThread ?? () {},
          icon: const Icon(Icons.add_rounded, size: 20),
          label: const Text('Buat Thread'),
          style: ElevatedButton.styleFrom(
            backgroundColor: CommunityColors.primary,
            foregroundColor: CommunityColors.textPrimary,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
    );
  }
}

