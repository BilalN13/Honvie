import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../controllers/checkin_controller.dart';
import '../widgets/checkin_reason_chip.dart';
import '../widgets/checkin_step_shell.dart';

class CheckinStep2ReasonsPage extends StatefulWidget {
  const CheckinStep2ReasonsPage({
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
  State<CheckinStep2ReasonsPage> createState() =>
      _CheckinStep2ReasonsPageState();
}

class _CheckinStep2ReasonsPageState extends State<CheckinStep2ReasonsPage> {
  static const List<String> _recentReasons = <String>[
    'famille',
    'estime de soi',
    'sommeil',
    'social',
  ];

  static const List<String> _allReasons = <String>[
    'travail',
    'loisirs',
    'famille',
    'rupture',
    'meteo',
    'couple',
    'fete',
    'amour',
    'estime de soi',
    'sommeil',
    'social',
    'nourriture',
    'argent',
    'fatigue',
    'solitude',
    'sante',
    'insomnie',
    'pression',
    'examens',
    'contenu',
    'motivation',
    'routine',
    'conflit',
    'autre',
  ];

  final TextEditingController _searchController = TextEditingController();
  bool _showAllReasons = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _updateSearch(String value) {
    setState(() {});
  }

  bool _matchesQuery(String value) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      return true;
    }

    return value.toLowerCase().contains(query);
  }

  List<String> _filteredReasons(List<String> reasons) {
    return reasons.where(_matchesQuery).toList();
  }

  @override
  Widget build(BuildContext context) {
    final recentReasons = _filteredReasons(_recentReasons);
    final allReasons = _filteredReasons(_allReasons);
    final shouldShowAll =
        _showAllReasons || _searchController.text.trim().isNotEmpty;
    final visibleReasons = shouldShowAll
        ? allReasons
        : allReasons.take(12).toList();

    return CheckInStepShell(
      currentStep: 2,
      totalSteps: 4,
      completionLevel: widget.controller.completionLevel,
      title: 'Quelles raisons te font te sentir ainsi ?',
      subtitle: 'Selectionne les raisons qui influencent ton emotion actuelle.',
      primaryLabel: 'Continuer',
      onPrimaryPressed: widget.controller.canContinueFromReasons
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
            onChanged: _updateSearch,
            decoration: InputDecoration(
              hintText: 'Rechercher et ajouter des raisons',
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
          const SizedBox(height: 20),
          _ReasonSection(
            title: 'Recemment utilisees',
            children: recentReasons.map((String reason) {
              return CheckInReasonChip(
                label: reason,
                isSelected: widget.controller.reasons.contains(reason),
                onTap: () => widget.controller.toggleReason(reason),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          _ReasonSection(
            title: 'Toutes les raisons',
            children: <Widget>[
              ...visibleReasons.map((String reason) {
                return CheckInReasonChip(
                  label: reason,
                  isSelected: widget.controller.reasons.contains(reason),
                  onTap: () => widget.controller.toggleReason(reason),
                );
              }),
              if (!_showAllReasons &&
                  _searchController.text.trim().isEmpty &&
                  allReasons.length > visibleReasons.length)
                CheckInReasonChip(
                  label: 'Plus',
                  leadingIcon: Icons.add_rounded,
                  isSelected: false,
                  onTap: () {
                    setState(() {
                      _showAllReasons = true;
                    });
                  },
                ),
            ],
          ),
          if (recentReasons.isEmpty && allReasons.isEmpty) ...<Widget>[
            const SizedBox(height: 18),
            Text(
              'Aucune raison ne correspond a cette recherche.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }
}

class _ReasonSection extends StatelessWidget {
  const _ReasonSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
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
        const SizedBox(height: 12),
        Wrap(spacing: 12, runSpacing: 12, children: children),
      ],
    );
  }
}
