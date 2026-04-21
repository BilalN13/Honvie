import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../journal/constants/checkin_mappings.dart';
import '../../journal/models/checkin_record.dart';
import '../models/history_item.dart';

class HistoryMomentCard extends StatelessWidget {
  const HistoryMomentCard({super.key, required this.item, this.onTap});

  final HistoryItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final emotionColor = CheckinMappings.colorForEmotion(item.currentEmotion);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.74),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.9)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(
                      color: emotionColor.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      CheckinMappings.emojiForEmotion(item.currentEmotion),
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          CheckinMappings.labelForEmotion(item.currentEmotion),
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: AppColors.ink,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _formatMomentDate(item),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.mutedInk,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.mutedInk,
                    size: 22,
                  ),
                ],
              ),
              if (item.reasons.isNotEmpty) ...<Widget>[
                const SizedBox(height: 14),
                _SectionLabel(label: 'Pourquoi'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: item.reasons
                      .map((String reason) => _ReasonChip(label: reason))
                      .toList(),
                ),
              ],
              const SizedBox(height: 14),
              _DetailRow(
                label: 'Je voulais',
                value: CheckinMappings.labelForDesiredEmotion(
                  item.desiredEmotion,
                ),
              ),
              if (item.activity != null &&
                  item.activity!.trim().isNotEmpty) ...<Widget>[
                const SizedBox(height: 8),
                _DetailRow(label: 'Activite', value: item.activity!),
              ],
              if (item.hasPlaceContext) ...<Widget>[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSoft,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          const Icon(
                            Icons.place_rounded,
                            color: AppColors.ink,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item.selectedPlaceName ?? 'Lieu ajoute plus tard',
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: AppColors.ink,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (item.selectedPlaceStatus != null) ...<Widget>[
                        const SizedBox(height: 10),
                        _StatusBadge(status: item.selectedPlaceStatus!),
                      ],
                    ],
                  ),
                ),
              ],
              if (item.hasWrittenNote) ...<Widget>[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.88),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _SectionLabel(label: 'Ma note'),
                      const SizedBox(height: 8),
                      Text(
                        item.writtenNote!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.ink,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (item.insightText != null) ...<Widget>[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.88),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _SectionLabel(label: 'Ce moment'),
                      const SizedBox(height: 8),
                      Text(
                        item.insightText!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.ink,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatMomentDate(HistoryItem item) {
    const List<String> months = <String>[
      'jan',
      'fev',
      'mar',
      'avr',
      'mai',
      'jun',
      'jul',
      'aou',
      'sep',
      'oct',
      'nov',
      'dec',
    ];

    final value = item.momentDateTime;
    final day = value.day.toString().padLeft(2, '0');
    final month = months[value.month - 1];

    if (!item.hasPreciseTime) {
      return '$day $month ${value.year}';
    }

    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$day $month ${value.year} a $hour:$minute';
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: AppColors.mutedInk,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _ReasonChip extends StatelessWidget {
  const _ReasonChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.warmCream,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppColors.ink,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: 82,
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.mutedInk,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final CheckinPlaceStatus status;

  @override
  Widget build(BuildContext context) {
    final (IconData icon, Color background) = switch (status) {
      CheckinPlaceStatus.favorite => (
        Icons.favorite_rounded,
        AppColors.primaryPink.withValues(alpha: 0.24),
      ),
      CheckinPlaceStatus.later => (
        Icons.bookmark_add_rounded,
        AppColors.warning.withValues(alpha: 0.26),
      ),
      CheckinPlaceStatus.visited => (
        Icons.check_circle_rounded,
        AppColors.success.withValues(alpha: 0.24),
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 15, color: AppColors.ink),
          const SizedBox(width: 6),
          Text(
            status.label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.ink,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
