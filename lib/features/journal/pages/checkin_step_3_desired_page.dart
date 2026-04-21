import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../controllers/checkin_controller.dart';
import '../widgets/checkin_emotion_picker_item.dart';
import '../widgets/checkin_step_shell.dart';

class CheckinStep3DesiredPage extends StatefulWidget {
  const CheckinStep3DesiredPage({
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
  State<CheckinStep3DesiredPage> createState() =>
      _CheckinStep3DesiredPageState();
}

class _CheckinStep3DesiredPageState extends State<CheckinStep3DesiredPage> {
  static const List<_DesiredOption> _recentOptions = <_DesiredOption>[
    _DesiredOption(label: 'posé', value: 'pose', emoji: '😌'),
    _DesiredOption(label: 'motivé', value: 'motive', emoji: '💪'),
    _DesiredOption(label: 'social', value: 'social', emoji: '🥳'),
    _DesiredOption(label: 'créatif', value: 'creatif', emoji: '🎨'),
  ];

  static const List<_DesiredOption> _allOptions = <_DesiredOption>[
    _DesiredOption(label: 'motivé', value: 'motive', emoji: '💪'),
    _DesiredOption(label: 'posé', value: 'pose', emoji: '😌'),
    _DesiredOption(label: 'curieux', value: 'curieux', emoji: '🧐'),
    _DesiredOption(label: 'créatif', value: 'creatif', emoji: '🎨'),
    _DesiredOption(label: 'social', value: 'social', emoji: '🥳'),
    _DesiredOption(label: 'introspectif', value: 'introspectif', emoji: '🌙'),
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

  bool _matches(_DesiredOption option) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      return true;
    }

    return option.label.toLowerCase().contains(query);
  }

  List<_DesiredOption> _filter(List<_DesiredOption> options) {
    return options.where(_matches).toList();
  }

  @override
  Widget build(BuildContext context) {
    final recentOptions = _filter(_recentOptions);
    final allOptions = _filter(_allOptions);

    return CheckInStepShell(
      currentStep: 3,
      totalSteps: 4,
      completionLevel: widget.controller.completionLevel,
      title: 'Vers quelle humeur veux-tu aller ?',
      subtitle: 'Choisis celle qui te ferait le plus de bien maintenant.',
      primaryLabel: 'Continuer',
      onPrimaryPressed: widget.controller.canContinueFromDesired
          ? widget.onNext
          : null,
      onClosePressed: widget.onClose,
      secondaryLabel: 'Retour',
      onSecondaryPressed: widget.onBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Rechercher une émotion',
              hintStyle: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.mutedInk),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: AppColors.mutedInk,
              ),
              filled: true,
              fillColor: AppColors.warmCream,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(999),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(999),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(999),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 22),
          _EmotionSection(
            title: 'Récentes',
            options: recentOptions,
            selectedValue: widget.controller.desiredEmotion,
            onSelect: widget.controller.selectDesiredEmotion,
          ),
          const SizedBox(height: 22),
          _EmotionSection(
            title: 'Toutes les émotions',
            options: allOptions,
            selectedValue: widget.controller.desiredEmotion,
            onSelect: widget.controller.selectDesiredEmotion,
          ),
          if (recentOptions.isEmpty && allOptions.isEmpty) ...<Widget>[
            const SizedBox(height: 18),
            Text(
              'Aucune émotion ne correspond à cette recherche.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }
}

class _EmotionSection extends StatelessWidget {
  const _EmotionSection({
    required this.title,
    required this.options,
    required this.selectedValue,
    required this.onSelect,
  });

  final String title;
  final List<_DesiredOption> options;
  final String? selectedValue;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) {
      return const SizedBox.shrink();
    }

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
          spacing: 10,
          runSpacing: 18,
          children: options.map((option) {
            return CheckinEmotionPickerItem(
              label: option.label,
              emoji: option.emoji,
              isSelected: selectedValue == option.value,
              onTap: () => onSelect(option.value),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _DesiredOption {
  const _DesiredOption({
    required this.label,
    required this.value,
    required this.emoji,
  });

  final String label;
  final String value;
  final String emoji;
}
