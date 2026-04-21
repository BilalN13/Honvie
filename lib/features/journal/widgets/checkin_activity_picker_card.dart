import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';

class CheckinActivityPickerCard extends StatelessWidget {
  const CheckinActivityPickerCard({
    super.key,
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final IconData icon;
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
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isSelected ? AppColors.primaryPink : AppColors.border,
            ),
            gradient: isSelected ? AppGradients.morningLight : null,
            color: isSelected ? null : AppColors.white.withValues(alpha: 0.9),
            boxShadow: isSelected
                ? const <BoxShadow>[
                    BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 20,
                      offset: Offset(0, 10),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    height: 42,
                    width: 42,
                    decoration: BoxDecoration(
                      gradient: isSelected ? AppGradients.sunsetWarm : null,
                      color: isSelected ? null : AppColors.warmCream,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      icon,
                      size: 20,
                      color: isSelected ? AppColors.white : AppColors.ink,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    isSelected
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: 18,
                    color: isSelected
                        ? AppColors.primaryOrange
                        : AppColors.mutedInk,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(label, style: theme.textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 12,
                  color: AppColors.mutedInk,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
