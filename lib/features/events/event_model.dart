class EventItem {
  const EventItem({
    required this.title,
    required this.locationName,
    required this.dateTime,
    required this.category,
    required this.distanceKm,
    required this.latitude,
    required this.longitude,
    this.recommendationScore = 0,
    this.recommendationReason,
  });

  final String title;
  final String locationName;
  final DateTime dateTime;
  final String category;
  final double distanceKm;
  final double latitude;
  final double longitude;
  final int recommendationScore;
  final String? recommendationReason;

  EventItem copyWith({
    String? title,
    String? locationName,
    DateTime? dateTime,
    String? category,
    double? distanceKm,
    double? latitude,
    double? longitude,
    int? recommendationScore,
    String? recommendationReason,
  }) {
    return EventItem(
      title: title ?? this.title,
      locationName: locationName ?? this.locationName,
      dateTime: dateTime ?? this.dateTime,
      category: category ?? this.category,
      distanceKm: distanceKm ?? this.distanceKm,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      recommendationScore: recommendationScore ?? this.recommendationScore,
      recommendationReason: recommendationReason ?? this.recommendationReason,
    );
  }
}
