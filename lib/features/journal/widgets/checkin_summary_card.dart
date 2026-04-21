import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class CheckInSummaryCard extends StatelessWidget {
  const CheckInSummaryCard({
    super.key,
    required this.currentEmotion,
    required this.reasons,
    required this.desiredEmotion,
    required this.suggestedActivity,
  });

  final String? currentEmotion;
  final List<String> reasons;
  final String? desiredEmotion;
  final String? suggestedActivity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 24,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Recapitulatif', style: theme.textTheme.titleLarge),
          const SizedBox(height: 16),
          _SummaryRow(label: 'Emotion actuelle', value: currentEmotion ?? '-'),
          _SummaryRow(
            label: 'Raisons',
            value: reasons.isEmpty ? '-' : reasons.join(', '),
          ),
          _SummaryRow(
            label: 'Emotion recherchee',
            value: desiredEmotion ?? '-',
          ),
          _SummaryRow(
            label: 'Activite suggeree',
            value: suggestedActivity ?? '-',
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.mutedInk,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 5,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
