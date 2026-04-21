import 'package:flutter/foundation.dart';

import '../models/checkin_record.dart';

class CheckinController extends ChangeNotifier {
  String? currentEmotion;
  final List<String> reasons = <String>[];
  String? desiredEmotion;
  String? activity;
  int completionLevel = 0;

  void selectCurrentEmotion(String value) {
    currentEmotion = value;
    updateCompletionLevel();
  }

  void toggleReason(String value) {
    if (reasons.contains(value)) {
      reasons.remove(value);
    } else {
      reasons.add(value);
    }

    updateCompletionLevel();
  }

  void selectDesiredEmotion(String value) {
    desiredEmotion = value;
    updateCompletionLevel();
  }

  void selectActivity(String value) {
    activity = value;
    updateCompletionLevel();
  }

  void updateCompletionLevel() {
    completionLevel = 0;

    if (currentEmotion != null && currentEmotion!.isNotEmpty) {
      completionLevel += 1;
    }
    if (reasons.isNotEmpty) {
      completionLevel += 1;
    }
    if (desiredEmotion != null && desiredEmotion!.isNotEmpty) {
      completionLevel += 1;
    }
    if (activity != null && activity!.isNotEmpty) {
      completionLevel += 1;
    }

    notifyListeners();
  }

  bool get canContinueFromEmotion => currentEmotion != null;
  bool get canContinueFromReasons => reasons.isNotEmpty;
  bool get canContinueFromDesired => desiredEmotion != null;
  bool get canContinueFromActivity => activity != null;

  CheckinRecord toRecord({DateTime? date}) {
    return CheckinRecord(
      date: date ?? DateTime.now(),
      currentEmotion: currentEmotion,
      reasons: List<String>.from(reasons),
      desiredEmotion: desiredEmotion,
      activity: activity,
      completionLevel: completionLevel,
    );
  }

  void hydrateFromRecord(CheckinRecord? record, {bool notify = true}) {
    currentEmotion = record?.currentEmotion;
    reasons
      ..clear()
      ..addAll(record?.reasons ?? const <String>[]);
    desiredEmotion = record?.desiredEmotion;
    activity = record?.activity;
    completionLevel = record?.completionLevel ?? 0;

    if (notify) {
      notifyListeners();
    }
  }

  void reset() {
    currentEmotion = null;
    reasons.clear();
    desiredEmotion = null;
    activity = null;
    completionLevel = 0;
    notifyListeners();
  }
}
