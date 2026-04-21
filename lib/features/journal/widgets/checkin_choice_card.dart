import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';

class CheckInChoiceCard extends StatelessWidget {
  const CheckInChoiceCard({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
    this.emoji,
    this.assetPath,
    this.subtitle,
  });

  final String label;
  final String? subtitle;
  final IconData? icon;
  final String? emoji;
  final String? assetPath;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isSelected ? AppColors.rose : AppColors.border,
              width: isSelected ? 1.4 : 1,
            ),
            gradient: isSelected ? AppGradients.morningLight : null,
            color: isSelected ? null : AppColors.white.withValues(alpha: 0.82),
            boxShadow: isSelected
                ? const <BoxShadow>[
                    BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 22,
                      offset: Offset(0, 12),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color: assetPath != null
                      ? AppColors.transparent
                      : isSelected
                      ? AppColors.rose
                      : AppColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: assetPath != null
                      ? Image.asset(assetPath!, width: 40, height: 40)
                      : emoji != null
                      ? Text(emoji!, style: const TextStyle(fontSize: 22))
                      : Icon(
                          icon,
                          color: isSelected ? AppColors.white : AppColors.ink,
                          size: 22,
                        ),
                ),
              ),
              const Spacer(),
              Text(label, style: theme.textTheme.titleMedium),
              if (subtitle != null) ...<Widget>[
                const SizedBox(height: 6),
                Text(subtitle!, style: theme.textTheme.bodyMedium),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
