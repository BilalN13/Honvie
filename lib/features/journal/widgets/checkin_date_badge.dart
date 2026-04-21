import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class CheckinDateBadge extends StatelessWidget {
  const CheckinDateBadge({super.key, required this.date});

  final DateTime date;

  static const List<String> _weekdays = <String>[
    'lun.',
    'mar.',
    'mer.',
    'jeu.',
    'ven.',
    'sam.',
    'dim.',
  ];

  static const List<String> _months = <String>[
    'janv.',
    'fevr.',
    'mars',
    'avr.',
    'mai',
    'juin',
    'juil.',
    'aout',
    'sept.',
    'oct.',
    'nov.',
    'dec.',
  ];

  @override
  Widget build(BuildContext context) {
    final label =
        '${_weekdays[date.weekday - 1]} ${date.day} ${_months[date.month - 1]}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.warmCream,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
          const SizedBox(width: 6),
          const Icon(
            Icons.calendar_today_rounded,
            size: 13,
            color: AppColors.primaryPink,
          ),
        ],
      ),
    );
  }
}
