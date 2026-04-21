import '../../journal/models/checkin_record.dart';
import '../../recommendation/personalization_service.dart';
import '../../recommendation/recommendation_service.dart';

class HistoryItem {
  const HistoryItem({
    required this.id,
    required this.date,
    required this.momentDateTime,
    required this.hasPreciseTime,
    required this.currentEmotion,
    required this.reasons,
    required this.desiredEmotion,
    required this.activity,
    required this.completionLevel,
    required this.selectedPlaceName,
    required this.selectedPlaceStatus,
    required this.writtenNote,
    required this.insightText,
  });

  final String? id;
  final DateTime date;
  final DateTime momentDateTime;
  final bool hasPreciseTime;
  final String? currentEmotion;
  final List<String> reasons;
  final String? desiredEmotion;
  final String? activity;
  final int completionLevel;
  final String? selectedPlaceName;
  final CheckinPlaceStatus? selectedPlaceStatus;
  final String? writtenNote;
  final String? insightText;

  bool get hasPlaceContext {
    return (selectedPlaceName != null &&
            selectedPlaceName!.trim().isNotEmpty) ||
        selectedPlaceStatus != null;
  }

  bool get hasWrittenNote {
    return writtenNote != null && writtenNote!.trim().isNotEmpty;
  }

  factory HistoryItem.fromCheckinRecord(
    CheckinRecord record, {
    PersonalizationProfile personalizationProfile =
        PersonalizationProfile.empty,
  }) {
    final momentDateTime = record.updatedAt ?? record.createdAt ?? record.date;

    return HistoryItem(
      id: record.id,
      date: record.date,
      momentDateTime: momentDateTime,
      hasPreciseTime: record.updatedAt != null || record.createdAt != null,
      currentEmotion: record.currentEmotion,
      reasons: record.reasons,
      desiredEmotion: record.desiredEmotion,
      activity: record.activity,
      completionLevel: record.completionLevel,
      selectedPlaceName: record.selectedPlaceName,
      selectedPlaceStatus: record.selectedPlaceStatus,
      writtenNote: record.writtenNote,
      insightText: generateInsightText(
        currentEmotion: record.currentEmotion,
        reasons: record.reasons,
        desiredEmotion: record.desiredEmotion,
        activity: record.activity,
        selectedPlaceName: record.selectedPlaceName,
        selectedPlaceStatus: record.selectedPlaceStatus,
        personalizationProfile: personalizationProfile,
      ),
    );
  }

  static String? generateInsightText({
    required String? currentEmotion,
    required List<String> reasons,
    required String? desiredEmotion,
    required String? activity,
    required String? selectedPlaceName,
    required CheckinPlaceStatus? selectedPlaceStatus,
    required PersonalizationProfile personalizationProfile,
  }) {
    switch (selectedPlaceStatus) {
      case CheckinPlaceStatus.favorite:
        return 'Tu as garde ce lieu en favori pour y revenir.';
      case CheckinPlaceStatus.later:
        return 'Tu as choisi de garder ce lieu pour plus tard.';
      case CheckinPlaceStatus.visited:
        return 'Tu as marque ce lieu comme visite.';
      case null:
        break;
    }

    final hasRecurringPreference =
        selectedPlaceName != null &&
        selectedPlaceName.trim().isNotEmpty &&
        PersonalizationService.instance.hasRecurringPreference(
          profile: personalizationProfile,
          desiredEmotion: desiredEmotion,
          activity: activity,
        );

    if (hasRecurringPreference) {
      return 'Ce type de lieu semble t aider regulierement.';
    }

    return RecommendationService.instance.buildHistoryInsightBase(
      currentEmotion: currentEmotion,
      reasons: reasons,
      desiredEmotion: desiredEmotion,
    );
  }
}
