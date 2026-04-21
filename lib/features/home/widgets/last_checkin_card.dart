import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../models/home_models.dart';

class LastCheckInCard extends StatelessWidget {
  const LastCheckInCard({super.key, required this.snapshot});

  final LastCheckInSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.75)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            height: 24,
            width: 24,
            decoration: BoxDecoration(
              color: snapshot.accentColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(snapshot.emoji, style: const TextStyle(fontSize: 11)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  snapshot.title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.ink,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  snapshot.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 10,
                    color: AppColors.mutedInk,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primaryOrange,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: EdgeInsets.zero,
              textStyle: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }
}
