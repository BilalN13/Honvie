import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

Future<String?> showPlaceNoteDialog(
  BuildContext context, {
  String? initialValue,
  String title = 'Ajouter une note',
}) async {
  final controller = TextEditingController(text: initialValue ?? '');

  final result = await showDialog<String>(
    context: context,
    builder: (BuildContext context) {
      final theme = Theme.of(context);

      return AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(title, style: theme.textTheme.titleLarge),
        content: TextField(
          controller: controller,
          minLines: 3,
          maxLines: 5,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText: 'Note ce que tu veux garder de ce moment...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop(controller.text.trim());
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryOrange,
              foregroundColor: AppColors.softBlack,
            ),
            child: const Text('Enregistrer'),
          ),
        ],
      );
    },
  );

  controller.dispose();
  return result;
}
