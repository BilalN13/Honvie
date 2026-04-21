import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class HonvieBottomNavigationBar extends StatelessWidget {
  const HonvieBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.onCenterTap,
  });

  static const String _journalLogoAsset =
      'assets/images/honvie-icon-light-128.png';

  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback? onCenterTap;

  static const List<_NavItemData> _items = <_NavItemData>[
    _NavItemData(label: 'Accueil', icon: Icons.home_rounded, pageIndex: 0),
    _NavItemData(label: 'Explorer', icon: Icons.explore_rounded, pageIndex: 1),
    _NavItemData(
      label: 'Journal',
      icon: Icons.auto_stories_rounded,
      isCenter: true,
    ),
    _NavItemData(
      label: 'Historique',
      icon: Icons.history_rounded,
      pageIndex: 2,
    ),
    _NavItemData(label: 'Stats', icon: Icons.insights_rounded, pageIndex: 3),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(18, 0, 18, 18),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.82),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: AppColors.border),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 26,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: List<Widget>.generate(_items.length, (int index) {
                final item = _items[index];

                if (item.isCenter) {
                  return Expanded(
                    child: _CenterNavItem(
                      item: item,
                      selected: false,
                      onTap: onCenterTap ?? () => onTap(index),
                    ),
                  );
                }

                return Expanded(
                  child: _NavItem(
                    item: item,
                    selected: currentIndex == item.pageIndex,
                    onTap: () => onTap(item.pageIndex!),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _NavItemData item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final labelColor = selected ? AppColors.ink : AppColors.mutedInk;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: selected ? AppColors.surfaceSoft : Colors.transparent,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(item.icon, color: labelColor, size: 24),
            const SizedBox(height: 4),
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: labelColor,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CenterNavItem extends StatelessWidget {
  const _CenterNavItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _NavItemData item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              height: 68,
              width: 68,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 22,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.asset(
                  HonvieBottomNavigationBar._journalLogoAsset,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItemData {
  const _NavItemData({
    required this.label,
    required this.icon,
    this.isCenter = false,
    this.pageIndex,
  });

  final String label;
  final IconData icon;
  final bool isCenter;
  final int? pageIndex;
}
