import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';

class CheckinEmotionPickerItem extends StatelessWidget {
  const CheckinEmotionPickerItem({
    super.key,
    required this.label,
    required this.emoji,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final String emoji;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: AppColors.ink,
      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
      fontSize: 12,
    );

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 72,
        child: Column(
          children: <Widget>[
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              height: 64,
              width: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isSelected ? AppGradients.morningLight : null,
                color: isSelected ? null : AppColors.warmCream,
                border: Border.all(
                  color: isSelected ? AppColors.primaryPink : AppColors.border,
                ),
                boxShadow: isSelected
                    ? const <BoxShadow>[
                        BoxShadow(
                          color: AppColors.shadow,
                          blurRadius: 18,
                          offset: Offset(0, 8),
                        ),
                      ]
                    : null,
              ),
              alignment: Alignment.center,
              child: Text(emoji, style: const TextStyle(fontSize: 28)),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textStyle,
            ),
          ],
        ),
      ),
    );
  }
}
