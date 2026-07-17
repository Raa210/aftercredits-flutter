import 'package:flutter/material.dart';
import '../community_colors.dart';

/// Kategori pill/capsule yang dapat di-scroll horizontal.
class CategoryTabs extends StatelessWidget {
  final List<String> categories;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const CategoryTabs({
    super.key,
    required this.categories,
    required this.selectedIndex,
    required this.onSelected,
  });

  /// Icon untuk setiap kategori.
  IconData _iconForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'semua':
        return Icons.grid_view_rounded;
      case 'ending':
        return Icons.movie_filter_rounded;
      case 'teori':
        return Icons.lightbulb_outline_rounded;
      case 'spoiler talk':
        return Icons.warning_amber_rounded;
      case 'diskusi':
        return Icons.chat_bubble_outline_rounded;
      default:
        return Icons.label_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: CommunitySpacing.md,
        ),
        itemCount: categories.length,
        separatorBuilder: (_, __) =>
            const SizedBox(width: CommunitySpacing.sm),
        itemBuilder: (context, index) {
          final isActive = index == selectedIndex;
          final label = categories[index];

          return _CategoryPill(
            label: label,
            icon: _iconForCategory(label),
            isActive: isActive,
            onTap: () => onSelected(index),
          );
        },
      ),
    );
  }
}

class _CategoryPill extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _CategoryPill({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_CategoryPill> createState() => _CategoryPillState();
}

class _CategoryPillState extends State<_CategoryPill>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnim,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: widget.isActive
                ? CommunityColors.primary
                : CommunityColors.chipInactive,
            borderRadius: BorderRadius.circular(CommunityRadius.pill),
            border: widget.isActive
                ? null
                : Border.all(
                    color: CommunityColors.divider,
                    width: 1,
                  ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 16,
                color: widget.isActive
                    ? CommunityColors.textPrimary
                    : CommunityColors.chipInactiveText,
              ),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: TextStyle(
                  color: widget.isActive
                      ? CommunityColors.textPrimary
                      : CommunityColors.chipInactiveText,
                  fontSize: 13,
                  fontWeight:
                      widget.isActive ? FontWeight.w700 : FontWeight.w500,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
