enum CheckinPlaceStatus {
  favorite('favorite', 'Favori'),
  later('later', 'Plus tard'),
  visited('visited', 'Visite');

  const CheckinPlaceStatus(this.storageValue, this.label);

  final String storageValue;
  final String label;

  static CheckinPlaceStatus? fromStorage(String? value) {
    switch (value) {
      case 'favorite':
        return CheckinPlaceStatus.favorite;
      case 'later':
        return CheckinPlaceStatus.later;
      case 'visited':
        return CheckinPlaceStatus.visited;
      default:
        return null;
    }
  }
}

class CheckinRecord {
  const CheckinRecord({
    required this.date,
    required this.currentEmotion,
    required this.reasons,
    required this.desiredEmotion,
    required this.activity,
    required this.completionLevel,
    this.id,
    this.userId,
    this.createdAt,
    this.updatedAt,
    this.selectedPlaceName,
    this.selectedPlaceStatus,
    this.writtenNote,
  });

  final String? id;
  final String? userId;
  final DateTime date;
  final String? currentEmotion;
  final List<String> reasons;
  final String? desiredEmotion;
  final String? activity;
  final int completionLevel;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? selectedPlaceName;
  final CheckinPlaceStatus? selectedPlaceStatus;
  final String? writtenNote;

  bool get isComplete => completionLevel >= 4;

  int get nextStepIndex {
    if (currentEmotion == null || currentEmotion!.isEmpty) {
      return 0;
    }
    if (reasons.isEmpty) {
      return 1;
    }
    if (desiredEmotion == null || desiredEmotion!.isEmpty) {
      return 2;
    }
    if (activity == null || activity!.isEmpty) {
      return 3;
    }
    return 4;
  }

  CheckinRecord copyWith({
    String? id,
    String? userId,
    DateTime? date,
    String? currentEmotion,
    List<String>? reasons,
    String? desiredEmotion,
    String? activity,
    int? completionLevel,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? selectedPlaceName,
    CheckinPlaceStatus? selectedPlaceStatus,
    String? writtenNote,
  }) {
    return CheckinRecord(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      currentEmotion: currentEmotion ?? this.currentEmotion,
      reasons: reasons ?? this.reasons,
      desiredEmotion: desiredEmotion ?? this.desiredEmotion,
      activity: activity ?? this.activity,
      completionLevel: completionLevel ?? this.completionLevel,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      selectedPlaceName: selectedPlaceName ?? this.selectedPlaceName,
      selectedPlaceStatus: selectedPlaceStatus ?? this.selectedPlaceStatus,
      writtenNote: writtenNote ?? this.writtenNote,
    );
  }

  factory CheckinRecord.fromSupabase(Map<String, dynamic> map) {
    final reasons = map['reasons'];

    return CheckinRecord(
      id: map['id'] as String?,
      userId: map['user_id'] as String?,
      date: DateTime.parse(map['checkin_date'] as String),
      currentEmotion: map['current_emotion'] as String?,
      reasons: reasons is List<dynamic>
          ? reasons.map((item) => item.toString()).toList()
          : const <String>[],
      desiredEmotion: map['desired_emotion'] as String?,
      activity: map['activity'] as String?,
      completionLevel: (map['completion_level'] as num?)?.toInt() ?? 0,
      createdAt: map['created_at'] == null
          ? null
          : DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] == null
          ? null
          : DateTime.parse(map['updated_at'] as String),
      selectedPlaceName: map['selected_place_name'] as String?,
      selectedPlaceStatus: CheckinPlaceStatus.fromStorage(
        map['place_status'] as String?,
      ),
      writtenNote: map['written_note'] as String?,
    );
  }

  Map<String, dynamic> toSupabaseUpsert({
    required String userId,
    required DateTime now,
  }) {
    return <String, dynamic>{
      'user_id': userId,
      'checkin_date': _dateKey(date),
      'current_emotion': currentEmotion,
      'reasons': reasons,
      'desired_emotion': desiredEmotion,
      'activity': activity,
      'completion_level': completionLevel,
      'updated_at': now.toUtc().toIso8601String(),
      if (selectedPlaceName != null && selectedPlaceName!.trim().isNotEmpty)
        'selected_place_name': selectedPlaceName,
      if (selectedPlaceStatus != null)
        'place_status': selectedPlaceStatus!.storageValue,
      if (writtenNote != null && writtenNote!.trim().isNotEmpty)
        'written_note': writtenNote,
      if (createdAt == null) 'created_at': now.toUtc().toIso8601String(),
    };
  }

  static String dateKey(DateTime value) => _dateKey(value);

  static String _dateKey(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
