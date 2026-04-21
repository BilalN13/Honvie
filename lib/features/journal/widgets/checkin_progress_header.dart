import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';

class CheckInProgressHeader extends StatelessWidget {
  const CheckInProgressHeader({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.completionLevel,
    required this.onClosePressed,
    this.onBackPressed,
    this.leading,
  });

  final int currentStep;
  final int totalSteps;
  final int completionLevel;
  final VoidCallback onClosePressed;
  final VoidCallback? onBackPressed;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stepLabel = '$currentStep/$totalSteps';

    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            if (leading != null)
              leading!
            else
              SizedBox(
                height: 34,
                width: 34,
                child: onBackPressed == null
                    ? const SizedBox.shrink()
                    : IconButton(
                        onPressed: onBackPressed,
                        icon: const Icon(Icons.arrow_back_rounded, size: 18),
                        color: AppColors.ink,
                        splashRadius: 18,
                      ),
              ),
            Expanded(
              child: Text(
                stepLabel,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(
              height: 34,
              width: 34,
              child: IconButton(
                onPressed: onClosePressed,
                icon: const Icon(Icons.close_rounded, size: 18),
                color: AppColors.ink,
                splashRadius: 18,
                tooltip: 'Fermer',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: List<Widget>.generate(totalSteps, (int index) {
            final isFilled = index < currentStep;

            return Expanded(
              child: Container(
                height: 6,
                margin: EdgeInsets.only(right: index == totalSteps - 1 ? 0 : 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: isFilled ? AppGradients.sunsetWarm : null,
                  color: isFilled ? null : AppColors.surfaceSoft,
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            'Completion $completionLevel/4',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.mutedInk,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}
