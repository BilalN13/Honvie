import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.greeting,
    required this.dateBadgeLabel,
    required this.streakLabel,
    this.trailing,
    this.onTrailingPressed,
    this.trailingTooltip,
    this.trailingIcon = Icons.person_outline_rounded,
  });

  final String greeting;
  final String dateBadgeLabel;
  final String streakLabel;
  final Widget? trailing;
  final VoidCallback? onTrailingPressed;
  final String? trailingTooltip;
  final IconData trailingIcon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Expanded(
          child: Text(
            greeting,
            style: theme.textTheme.titleLarge?.copyWith(
              color: AppColors.ink,
              fontSize: 21,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 10),
        _HeaderBadge(
          label: dateBadgeLabel,
          icon: Icons.calendar_today_rounded,
          iconColor: AppColors.mutedInk,
        ),
        const SizedBox(width: 6),
        _HeaderBadge(label: streakLabel, emoji: '\u{1F525}'),
        if (trailing != null) ...<Widget>[
          const SizedBox(width: 6),
          trailing!,
        ] else if (onTrailingPressed != null) ...<Widget>[
          const SizedBox(width: 6),
          _HeaderActionButton(
            tooltip: trailingTooltip ?? 'Action',
            onPressed: onTrailingPressed!,
            icon: trailingIcon,
          ),
        ],
      ],
    );
  }
}

class _HeaderActionButton extends StatelessWidget {
  const _HeaderActionButton({
    required this.tooltip,
    required this.onPressed,
    required this.icon,
  });

  final String tooltip;
  final VoidCallback onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.9)),
          ),
          child: Icon(icon, size: 16, color: AppColors.ink),
        ),
      ),
    );
  }
}

class _HeaderBadge extends StatelessWidget {
  const _HeaderBadge({
    required this.label,
    this.icon,
    this.iconColor,
    this.emoji,
  });

  final String label;
  final IconData? icon;
  final Color? iconColor;
  final String? emoji;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.9)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (emoji != null)
            Text(emoji!, style: const TextStyle(fontSize: 12))
          else if (icon != null)
            Icon(icon, size: 12, color: iconColor),
          const SizedBox(width: 5),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.ink,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
