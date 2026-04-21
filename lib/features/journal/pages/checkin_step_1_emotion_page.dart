import 'package:flutter/material.dart';

import '../constants/checkin_emoji_assets.dart';
import '../controllers/checkin_controller.dart';
import '../widgets/checkin_date_badge.dart';
import '../widgets/checkin_emotion_wave_selector.dart';
import '../widgets/checkin_step_shell.dart';

class CheckinStep1EmotionPage extends StatelessWidget {
  const CheckinStep1EmotionPage({
    super.key,
    required this.controller,
    required this.onNext,
    required this.onClose,
  });

  final CheckinController controller;
  final VoidCallback onNext;
  final VoidCallback onClose;

  static const List<CheckinEmotionWaveOption> _options =
      <CheckinEmotionWaveOption>[
        CheckinEmotionWaveOption(
          label: 'enerve',
          assetPath: CheckinEmojiAssets.enerve,
        ),
        CheckinEmotionWaveOption(
          label: 'triste',
          assetPath: CheckinEmojiAssets.triste,
        ),
        CheckinEmotionWaveOption(
          label: 'neutre',
          assetPath: CheckinEmojiAssets.neutre,
        ),
        CheckinEmotionWaveOption(
          label: 'content',
          assetPath: CheckinEmojiAssets.content,
        ),
        CheckinEmotionWaveOption(
          label: 'joyeux',
          assetPath: CheckinEmojiAssets.joyeux,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return CheckInStepShell(
      currentStep: 1,
      totalSteps: 4,
      completionLevel: controller.completionLevel,
      title: 'Quelle est ton humeur du moment ?',
      subtitle:
          'Selectionne l humeur qui reflete le mieux ce que tu ressens en ce moment.',
      primaryLabel: 'Continuer',
      onPrimaryPressed: controller.canContinueFromEmotion ? onNext : null,
      onClosePressed: onClose,
      headerLeading: CheckinDateBadge(date: DateTime.now()),
      child: CheckinEmotionWaveSelector(
        options: _options,
        selectedLabel: controller.currentEmotion,
        onSelected: controller.selectCurrentEmotion,
      ),
    );
  }
}
