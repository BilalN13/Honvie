import 'package:flutter/material.dart';

class CheckInSummary {
  const CheckInSummary({
    required this.completedToday,
    required this.totalToday,
    required this.weeklyCheckIns,
    required this.note,
    required this.emoji,
    required this.dateBadge,
  });

  final int completedToday;
  final int totalToday;
  final int weeklyCheckIns;
  final String note;
  final String emoji;
  final String dateBadge;
}

class WeekDayStatus {
  const WeekDayStatus({
    required this.label,
    required this.dayNumber,
    required this.isSelected,
    this.marker,
  });

  final String label;
  final int dayNumber;
  final bool isSelected;
  final String? marker;
}

class MoodEntry {
  const MoodEntry({
    required this.label,
    required this.completionLevel,
    required this.color,
    this.emoji,
  });

  final String label;
  final int completionLevel;
  final Color color;
  final String? emoji;
}

class LastCheckInSnapshot {
  const LastCheckInSnapshot({
    required this.title,
    required this.description,
    required this.emoji,
    required this.accentColor,
  });

  final String title;
  final String description;
  final String emoji;
  final Color accentColor;
}

class NearbyPlace {
  const NearbyPlace({
    this.id,
    required this.name,
    required this.distance,
    required this.category,
    required this.icon,
    required this.types,
    this.moodTags = const <String>[],
    this.isUserPlace = false,
    bool? isUserAdded,
    this.socialProofCount = 0,
    this.popularMoodTag,
    this.latitude,
    this.longitude,
    this.distanceKm,
    this.recommendationScore = 0,
    this.recommendationReason,
    this.isContextMatch = false,
  }) : isUserAdded = isUserAdded ?? isUserPlace;

  final String? id;
  final String name;
  final String distance;
  final String category;
  final IconData icon;
  final List<String> types;
  final List<String> moodTags;
  final bool isUserPlace;
  final bool isUserAdded;
  final int socialProofCount;
  final String? popularMoodTag;
  final double? latitude;
  final double? longitude;
  final double? distanceKm;
  final int recommendationScore;
  final String? recommendationReason;
  final bool isContextMatch;

  NearbyPlace copyWith({
    String? id,
    String? name,
    String? distance,
    String? category,
    IconData? icon,
    List<String>? types,
    List<String>? moodTags,
    bool? isUserPlace,
    bool? isUserAdded,
    int? socialProofCount,
    String? popularMoodTag,
    double? latitude,
    double? longitude,
    double? distanceKm,
    int? recommendationScore,
    String? recommendationReason,
    bool? isContextMatch,
  }) {
    return NearbyPlace(
      id: id ?? this.id,
      name: name ?? this.name,
      distance: distance ?? this.distance,
      category: category ?? this.category,
      icon: icon ?? this.icon,
      types: types ?? this.types,
      moodTags: moodTags ?? this.moodTags,
      isUserPlace: isUserPlace ?? this.isUserPlace,
      isUserAdded: isUserAdded ?? this.isUserAdded,
      socialProofCount: socialProofCount ?? this.socialProofCount,
      popularMoodTag: popularMoodTag ?? this.popularMoodTag,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      distanceKm: distanceKm ?? this.distanceKm,
      recommendationScore: recommendationScore ?? this.recommendationScore,
      recommendationReason: recommendationReason ?? this.recommendationReason,
      isContextMatch: isContextMatch ?? this.isContextMatch,
    );
  }
}

class SuggestedActivity {
  const SuggestedActivity({
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final String tag;
  final IconData icon;
}
