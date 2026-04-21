import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class PlaceJournalActions extends StatelessWidget {
  const PlaceJournalActions({
    super.key,
    required this.onFavoritePressed,
    required this.onLaterPressed,
    required this.onVisitedPressed,
    required this.onNotePressed,
  });

  final VoidCallback onFavoritePressed;
  final VoidCallback onLaterPressed;
  final VoidCallback onVisitedPressed;
  final VoidCallback onNotePressed;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        _ActionChipButton(
          icon: Icons.favorite_border_rounded,
          label: 'Mettre en favori',
          onPressed: onFavoritePressed,
        ),
        _ActionChipButton(
          icon: Icons.bookmark_add_outlined,
          label: 'Garder pour plus tard',
          onPressed: onLaterPressed,
        ),
        _ActionChipButton(
          icon: Icons.check_circle_outline_rounded,
          label: 'Marquer comme visite',
          onPressed: onVisitedPressed,
        ),
        _ActionChipButton(
          icon: Icons.edit_note_rounded,
          label: 'Ajouter une note',
          onPressed: onNotePressed,
        ),
      ],
    );
  }
}

class _ActionChipButton extends StatelessWidget {
  const _ActionChipButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.ink,
        side: const BorderSide(color: AppColors.border),
        backgroundColor: AppColors.surfaceSoft,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      icon: Icon(icon, size: 16),
      label: Text(
        label,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: AppColors.ink,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
