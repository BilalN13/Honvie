import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../models/home_models.dart';

class CheckInProgressCard extends StatelessWidget {
  const CheckInProgressCard({super.key, required this.summary});

  final CheckInSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ratio = summary.totalToday == 0
        ? 0.0
        : summary.completedToday / summary.totalToday;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.powderPink.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: <Widget>[
          Container(
            height: 20,
            width: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.white, width: 1.4),
              color: AppColors.warmCream,
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              size: 10,
              color: AppColors.primaryOrange,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  "Today's check-in",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.ink,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: AppColors.white.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: ratio.clamp(0, 1),
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.primaryPink,
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${summary.completedToday}/${summary.totalToday}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      height: 22,
                      width: 22,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryOrange,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          summary.emoji,
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
