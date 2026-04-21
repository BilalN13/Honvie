import 'package:flutter/material.dart';

import '../controllers/checkin_controller.dart';
import '../widgets/checkin_activity_picker_card.dart';
import '../widgets/checkin_date_badge.dart';
import '../widgets/checkin_step_shell.dart';

class CheckinStep4ActivityPage extends StatefulWidget {
  const CheckinStep4ActivityPage({
    super.key,
    required this.controller,
    required this.onBack,
    required this.onNext,
    required this.onClose,
  });

  final CheckinController controller;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final VoidCallback onClose;

  @override
  State<CheckinStep4ActivityPage> createState() =>
      _CheckinStep4ActivityPageState();
}

class _CheckinStep4ActivityPageState extends State<CheckinStep4ActivityPage> {
  static const List<_ActivityOption> _suggestedOptions = <_ActivityOption>[
    _ActivityOption(
      label: 'marcher',
      subtitle: 'Quelques minutes dehors pour souffler.',
      icon: Icons.directions_walk_rounded,
    ),
    _ActivityOption(
      label: 'respiration',
      subtitle: 'Revenir au calme en douceur.',
      icon: Icons.air_rounded,
    ),
    _ActivityOption(
      label: 'cafe calme',
      subtitle: 'Te poser dans un endroit rassurant.',
      icon: Icons.local_cafe_rounded,
    ),
    _ActivityOption(
      label: 'ecrire',
      subtitle: 'Mettre des mots sur ce que tu ressens.',
      icon: Icons.edit_note_rounded,
    ),
  ];

  static const List<_ActivityOption> _allOptions = <_ActivityOption>[
    _ActivityOption(
      label: 'marcher',
      subtitle: 'Quelques minutes dehors pour souffler.',
      icon: Icons.directions_walk_rounded,
    ),
    _ActivityOption(
      label: 'cafe calme',
      subtitle: 'Te poser dans un endroit rassurant.',
      icon: Icons.local_cafe_rounded,
    ),
    _ActivityOption(
      label: 'musee',
      subtitle: 'Changer d ambiance et prendre l air.',
      icon: Icons.museum_rounded,
    ),
    _ActivityOption(
      label: 'lecture',
      subtitle: 'T offrir un moment plus lent.',
      icon: Icons.menu_book_rounded,
    ),
    _ActivityOption(
      label: 'ecrire',
      subtitle: 'Mettre des mots sur ce que tu ressens.',
      icon: Icons.edit_note_rounded,
    ),
    _ActivityOption(
      label: 'bord de mer',
      subtitle: 'Retrouver une sensation d espace.',
      icon: Icons.water_rounded,
    ),
    _ActivityOption(
      label: 'cinema',
      subtitle: 'Decrocher un moment en douceur.',
      icon: Icons.local_movies_rounded,
    ),
    _ActivityOption(
      label: 'respiration',
      subtitle: 'Revenir au calme en douceur.',
      icon: Icons.air_rounded,
    ),
    _ActivityOption(
      label: 'pause gourmande',
      subtitle: 'Te reconforter avec quelque chose de simple.',
      icon: Icons.icecream_rounded,
    ),
  ];

  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String _) {
    setState(() {});
  }

  bool _matches(_ActivityOption option) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      return true;
    }

    return option.label.toLowerCase().contains(query) ||
        option.subtitle.toLowerCase().contains(query);
  }

  List<_ActivityOption> _filter(List<_ActivityOption> options) {
    return options.where(_matches).toList();
  }

  @override
  Widget build(BuildContext context) {
    final suggestedOptions = _filter(_suggestedOptions);
    final allOptions = _filter(_allOptions);

    return CheckInStepShell(
      currentStep: 4,
      totalSteps: 4,
      completionLevel: widget.controller.completionLevel,
      title: 'Quelle activite pourrait t aider ?',
      subtitle:
          'Choisis une piste douce et concrete pour prendre soin de toi maintenant.',
      primaryLabel: 'Continuer',
      onPrimaryPressed: widget.controller.canContinueFromActivity
          ? widget.onNext
          : null,
      onClosePressed: widget.onClose,
      secondaryLabel: 'Retour',
      onSecondaryPressed: widget.onBack,
      headerLeading: CheckinDateBadge(date: DateTime.now()),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Rechercher une activite',
              prefixIcon: const Icon(Icons.search_rounded),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 16,
              ),
            ),
          ),
          const SizedBox(height: 22),
          _ActivitySection(
            title: 'Suggestions du moment',
            options: suggestedOptions,
            selectedValue: widget.controller.activity,
            onSelect: widget.controller.selectActivity,
          ),
          const SizedBox(height: 22),
          _ActivitySection(
            title: 'Toutes les activites',
            options: allOptions,
            selectedValue: widget.controller.activity,
            onSelect: widget.controller.selectActivity,
          ),
          if (suggestedOptions.isEmpty && allOptions.isEmpty) ...<Widget>[
            const SizedBox(height: 18),
            Text(
              'Aucune activite ne correspond a cette recherche.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }
}

class _ActivitySection extends StatelessWidget {
  const _ActivitySection({
    required this.title,
    required this.options,
    required this.selectedValue,
    required this.onSelect,
  });

  final String title;
  final List<_ActivityOption> options;
  final String? selectedValue;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        const spacing = 12.0;
        final cardWidth = (constraints.maxWidth - spacing) / 2;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: options.map((option) {
                return SizedBox(
                  width: cardWidth,
                  child: CheckinActivityPickerCard(
                    label: option.label,
                    subtitle: option.subtitle,
                    icon: option.icon,
                    isSelected: selectedValue == option.label,
                    onTap: () => onSelect(option.label),
                  ),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }
}

class _ActivityOption {
  const _ActivityOption({
    required this.label,
    required this.subtitle,
    required this.icon,
  });

  final String label;
  final String subtitle;
  final IconData icon;
}
