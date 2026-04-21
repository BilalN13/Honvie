import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../journal/constants/checkin_mappings.dart';
import '../../journal/models/checkin_record.dart';
import '../models/history_item.dart';

class HistoryMomentDetailPage extends StatelessWidget {
  const HistoryMomentDetailPage({super.key, required this.item});

  final HistoryItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final emotionColor = CheckinMappings.colorForEmotion(item.currentEmotion);

    return Scaffold(
      backgroundColor: AppColors.white,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[AppColors.ivory, AppColors.blush, AppColors.mist],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                child: Row(
                  children: <Widget>[
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.white.withValues(alpha: 0.8),
                      ),
                      icon: const Icon(Icons.arrow_back_rounded),
                      color: AppColors.ink,
                    ),
                    const SizedBox(width: 8),
                    Text('Moment', style: theme.textTheme.headlineSmall),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 126),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _DetailHeroCard(item: item, emotionColor: emotionColor),
                      const SizedBox(height: 12),
                      if (item.reasons.isNotEmpty) ...<Widget>[
                        _DetailSection(
                          title: 'Pourquoi',
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: item.reasons.map((String reason) {
                              return _ReasonChip(label: reason);
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      _DetailSection(
                        title: 'Ce que tu cherchais',
                        child: Column(
                          children: <Widget>[
                            _DetailRow(
                              label: 'Emotion',
                              value: CheckinMappings.labelForDesiredEmotion(
                                item.desiredEmotion,
                              ),
                            ),
                            if (item.activity != null &&
                                item.activity!.trim().isNotEmpty) ...<Widget>[
                              const SizedBox(height: 10),
                              _DetailRow(
                                label: 'Activite',
                                value: item.activity!,
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (item.hasPlaceContext) ...<Widget>[
                        const SizedBox(height: 12),
                        _DetailSection(
                          title: 'Lieu choisi',
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
                                      item.selectedPlaceName ??
                                          'Lieu ajoute plus tard',
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
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
                        _DetailSection(
                          title: 'Ta note',
                          child: Text(
                            item.writtenNote!,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: AppColors.ink,
                              height: 1.45,
                            ),
                          ),
                        ),
                      ],
                      if (item.insightText != null) ...<Widget>[
                        const SizedBox(height: 12),
                        _DetailSection(
                          title: item.hasWrittenNote
                              ? 'Ce que ce moment raconte'
                              : 'Ce moment',
                          child: Text(
                            item.insightText!,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: AppColors.ink,
                              height: 1.45,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailHeroCard extends StatelessWidget {
  const _DetailHeroCard({required this.item, required this.emotionColor});

  final HistoryItem item;
  final Color emotionColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            height: 62,
            width: 62,
            decoration: BoxDecoration(
              color: emotionColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              CheckinMappings.emojiForEmotion(item.currentEmotion),
              style: const TextStyle(fontSize: 28),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  CheckinMappings.labelForEmotion(item.currentEmotion),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _formatMomentDate(item),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppColors.mutedInk,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
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

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
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
          width: 86,
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
            style: theme.textTheme.bodyLarge?.copyWith(
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
