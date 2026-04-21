import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import 'checkin_progress_header.dart';

class CheckInStepShell extends StatelessWidget {
  const CheckInStepShell({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.completionLevel,
    required this.title,
    required this.subtitle,
    required this.child,
    required this.primaryLabel,
    required this.onPrimaryPressed,
    required this.onClosePressed,
    this.secondaryLabel,
    this.onSecondaryPressed,
    this.headerLeading,
  });

  final int currentStep;
  final int totalSteps;
  final int completionLevel;
  final String title;
  final String subtitle;
  final Widget child;
  final String primaryLabel;
  final VoidCallback? onPrimaryPressed;
  final VoidCallback onClosePressed;
  final String? secondaryLabel;
  final VoidCallback? onSecondaryPressed;
  final Widget? headerLeading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Container(
        color: AppColors.white,
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            CheckInProgressHeader(
              currentStep: currentStep,
              totalSteps: totalSteps,
              completionLevel: completionLevel,
              onClosePressed: onClosePressed,
              onBackPressed: onSecondaryPressed,
              leading: headerLeading,
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineMedium?.copyWith(fontSize: 28),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: child,
              ),
            ),
            const SizedBox(height: 14),
            if (secondaryLabel != null && onSecondaryPressed != null)
              Align(
                alignment: Alignment.center,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: TextButton(
                    onPressed: onSecondaryPressed,
                    child: Text(secondaryLabel!),
                  ),
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onPrimaryPressed,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryOrange,
                  foregroundColor: AppColors.white,
                  disabledBackgroundColor: AppColors.border,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(primaryLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
