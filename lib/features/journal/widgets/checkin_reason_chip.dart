import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class CheckInReasonChip extends StatelessWidget {
  const CheckInReasonChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.leadingIcon,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? leadingIcon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isSelected ? AppColors.rose : AppColors.border,
            ),
            color: isSelected
                ? AppColors.rose.withValues(alpha: 0.14)
                : AppColors.white.withValues(alpha: 0.82),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (leadingIcon != null) ...<Widget>[
                Icon(leadingIcon, size: 16, color: AppColors.ink),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
