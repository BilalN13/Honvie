import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class PagePlaceholder extends StatelessWidget {
  const PagePlaceholder({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentLabel,
    this.highlight = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String accentLabel;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: highlight
                    ? AppColors.rose
                    : Colors.white.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: highlight ? AppColors.rose : AppColors.border,
                ),
              ),
              child: Text(
                accentLabel,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: highlight ? Colors.white : AppColors.ink,
                ),
              ),
            ),
            const Spacer(),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: AppColors.border),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 30,
                    offset: Offset(0, 18),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    height: 64,
                    width: 64,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: highlight
                            ? const <Color>[AppColors.rose, AppColors.peach]
                            : const <Color>[
                                AppColors.peach,
                                AppColors.surfaceSoft,
                              ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Icon(
                      icon,
                      color: highlight ? Colors.white : AppColors.ink,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(title, style: theme.textTheme.displaySmall),
                  const SizedBox(height: 12),
                  Text(subtitle, style: theme.textTheme.bodyLarge),
                ],
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
