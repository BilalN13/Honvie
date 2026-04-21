import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../checkin/data/checkin_service.dart';
import '../constants/checkin_emoji_assets.dart';
import '../constants/checkin_mappings.dart';
import '../controllers/checkin_controller.dart';
import '../controllers/local_checkin_store.dart';
import 'checkin_step_1_emotion_page.dart';
import 'checkin_step_2_reasons_page.dart';
import 'checkin_step_3_desired_page.dart';
import 'checkin_step_4_activity_page.dart';
import 'checkin_summary_page.dart';

class JournalPage extends StatefulWidget {
  const JournalPage({super.key});

  @override
  State<JournalPage> createState() => _JournalPageState();
}

class _JournalPageState extends State<JournalPage> {
  final CheckinController _controller = CheckinController();
  final LocalCheckinStore _store = LocalCheckinStore.instance;
  final CheckinService _service = CheckinService.instance;
  int _currentScreenIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller.hydrateFromRecord(_store.journalSeedRecord, notify: false);
    _currentScreenIndex = _store.journalEntryIndex;
    _controller.addListener(_syncDraft);
  }

  @override
  void dispose() {
    _controller.removeListener(_syncDraft);
    _controller.dispose();
    super.dispose();
  }

  void _goToScreen(int index) {
    setState(() {
      _currentScreenIndex = index;
    });
  }

  void _closeFlow([bool shouldReturnHome = false]) {
    Navigator.of(context).pop(shouldReturnHome);
  }

  void _syncDraft() {
    _store.syncDraft(_controller.toRecord());
  }

  Future<void> _validateCheckin() async {
    final record = _controller.toRecord();
    final message = CheckinMappings.validationMessage(
      currentEmotion: _controller.currentEmotion,
      desiredEmotion: _controller.desiredEmotion,
      activity: _controller.activity,
    );
    final suggestion = CheckinMappings.validationSuggestion(
      _controller.activity,
    );

    try {
      await _service.upsertTodayCheckin(record);
      _store.applyValidatedRecord(record);
      await _store.refreshFromRemote();
    } catch (_) {
      if (!mounted) {
        return;
      }

      await showDialog<void>(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: const Text('Synchronisation impossible'),
            content: const Text(
              'Le check-in n a pas pu etre enregistre dans Supabase pour le moment.',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Fermer'),
              ),
            ],
          );
        },
      );
      return;
    }

    if (!mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: AppColors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 26),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  height: 92,
                  width: 92,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppGradients.sunsetWarm,
                  ),
                  alignment: Alignment.center,
                  child: Image.asset(
                    CheckinEmojiAssets.joyeux,
                    width: 68,
                    height: 68,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  suggestion,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      _closeFlow(true);
                    },
                    child: const Text('Retour a l accueil'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge(<Listenable>[_controller, _store]),
      builder: (BuildContext context, _) {
        final isViewingCompletedSummary =
            _currentScreenIndex == 4 &&
            _store.draftForToday == null &&
            (_store.todayRecord?.isComplete ?? false);

        switch (_currentScreenIndex) {
          case 0:
            return CheckinStep1EmotionPage(
              controller: _controller,
              onNext: () => _goToScreen(1),
              onClose: _closeFlow,
            );
          case 1:
            return CheckinStep2ReasonsPage(
              controller: _controller,
              onBack: () => _goToScreen(0),
              onNext: () => _goToScreen(2),
              onClose: _closeFlow,
            );
          case 2:
            return CheckinStep3DesiredPage(
              controller: _controller,
              onBack: () => _goToScreen(1),
              onNext: () => _goToScreen(3),
              onClose: _closeFlow,
            );
          case 3:
            return CheckinStep4ActivityPage(
              controller: _controller,
              onBack: () => _goToScreen(2),
              onNext: () => _goToScreen(4),
              onClose: _closeFlow,
            );
          case 4:
            return CheckinSummaryPage(
              controller: _controller,
              onBack: () => _goToScreen(3),
              onValidate: isViewingCompletedSummary
                  ? _closeFlow
                  : _validateCheckin,
              onClose: _closeFlow,
              primaryLabel: isViewingCompletedSummary
                  ? 'Fermer'
                  : 'Valider mon check-in',
            );
          default:
            return const SizedBox.shrink();
        }
      },
    );
  }
}
