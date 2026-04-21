import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../models/home_models.dart';

class MoodChartCard extends StatelessWidget {
  const MoodChartCard({super.key, required this.entries});

  final List<MoodEntry> entries;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.lavender,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Mood chart',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.ink,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 150,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List<Widget>.generate(entries.length, (int index) {
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: index == entries.length - 1 ? 0 : 6,
                    ),
                    child: _MoodColumn(entry: entries[index]),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _MoodColumn extends StatelessWidget {
  const _MoodColumn({required this.entry});

  final MoodEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ratio = (entry.completionLevel.clamp(0, 4)) / 4;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: <Widget>[
        Expanded(
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final trackHeight = constraints.maxHeight - 16;
              final fillHeight = (trackHeight * ratio).clamp(24.0, trackHeight);
              final emojiBottom = (fillHeight - 6).clamp(
                10.0,
                trackHeight - 18,
              );

              return Stack(
                alignment: Alignment.bottomCenter,
                clipBehavior: Clip.none,
                children: <Widget>[
                  Positioned(
                    bottom: 0,
                    child: Container(
                      width: 10,
                      height: trackHeight,
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    child: Container(
                      width: 10,
                      height: fillHeight,
                      decoration: BoxDecoration(
                        color: entry.color,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  if (entry.emoji != null)
                    Positioned(
                      bottom: emojiBottom,
                      child: Text(
                        entry.emoji!,
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Text(
          entry.label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.mutedInk,
            fontSize: 8.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
