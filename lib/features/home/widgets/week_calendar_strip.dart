import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../models/home_models.dart';

class WeekCalendarStrip extends StatelessWidget {
  const WeekCalendarStrip({super.key, required this.days});

  final List<WeekDayStatus> days;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        const spacing = 8.0;
        final itemWidth =
            (constraints.maxWidth - (spacing * (days.length - 1))) /
            days.length;

        return SizedBox(
          height: 82,
          child: Row(
            children: List<Widget>.generate(days.length, (int index) {
              return Padding(
                padding: EdgeInsets.only(
                  right: index == days.length - 1 ? 0 : spacing,
                ),
                child: SizedBox(
                  width: itemWidth,
                  child: _WeekDayItem(day: days[index]),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}

class _WeekDayItem extends StatelessWidget {
  const _WeekDayItem({required this.day});

  final WeekDayStatus day;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSelected = day.isSelected;

    return Container(
      padding: EdgeInsets.symmetric(
        vertical: isSelected ? 8 : 7,
        horizontal: isSelected ? 2 : 0,
      ),
      decoration: BoxDecoration(
        gradient: isSelected ? AppGradients.eveningGlow : null,
        color: isSelected ? null : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? AppColors.transparent
              : AppColors.border.withValues(alpha: 0.75),
        ),
        boxShadow: isSelected
            ? const <BoxShadow>[
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 14,
                  offset: Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(
            day.label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: isSelected ? 10.5 : 10,
              fontWeight: FontWeight.w600,
              color: isSelected ? AppColors.white : AppColors.mutedInk,
            ),
          ),
          Text(
            '${day.dayNumber}',
            style: theme.textTheme.titleMedium?.copyWith(
              fontSize: isSelected ? 15 : 14,
              fontWeight: FontWeight.w700,
              color: isSelected ? AppColors.white : AppColors.ink,
            ),
          ),
          SizedBox(
            height: 12,
            child: day.marker == null
                ? Container(
                    height: isSelected ? 5 : 4,
                    width: isSelected ? 5 : 4,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.white.withValues(alpha: 0.85)
                          : AppColors.border,
                      shape: BoxShape.circle,
                    ),
                  )
                : Text(
                    day.marker!,
                    style: TextStyle(fontSize: isSelected ? 11 : 10),
                  ),
          ),
        ],
      ),
    );
  }
}
