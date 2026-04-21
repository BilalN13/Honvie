import 'package:flutter/material.dart';

import '../controllers/checkin_controller.dart';
import '../widgets/checkin_step_shell.dart';
import '../widgets/checkin_summary_card.dart';

class CheckinSummaryPage extends StatelessWidget {
  const CheckinSummaryPage({
    super.key,
    required this.controller,
    required this.onBack,
    required this.onValidate,
    required this.onClose,
    this.primaryLabel = 'Valider mon check-in',
  });

  final CheckinController controller;
  final VoidCallback onBack;
  final VoidCallback onValidate;
  final VoidCallback onClose;
  final String primaryLabel;

  @override
  Widget build(BuildContext context) {
    return CheckInStepShell(
      currentStep: 4,
      totalSteps: 4,
      completionLevel: controller.completionLevel,
      title: 'Recapitulatif',
      subtitle: 'Verifie ton check-in avant validation.',
      primaryLabel: primaryLabel,
      onPrimaryPressed: onValidate,
      onClosePressed: onClose,
      secondaryLabel: 'Retour',
      onSecondaryPressed: onBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CheckInSummaryCard(
            currentEmotion: controller.currentEmotion,
            reasons: controller.reasons,
            desiredEmotion: controller.desiredEmotion,
            suggestedActivity: controller.activity,
          ),
          const SizedBox(height: 12),
          Text(
            'Progression ${controller.completionLevel}/4',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
