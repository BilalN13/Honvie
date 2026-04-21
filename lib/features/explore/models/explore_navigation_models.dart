enum ExploreFilterType {
  all,
  forMe,
  myPlaces,
  events;

  String get label {
    switch (this) {
      case ExploreFilterType.all:
        return 'Tous';
      case ExploreFilterType.forMe:
        return 'Pour moi';
      case ExploreFilterType.myPlaces:
        return 'Mes lieux';
      case ExploreFilterType.events:
        return 'Evenements';
    }
  }
}

class ExploreViewRequest {
  const ExploreViewRequest({required this.filter, required this.requestId});

  final ExploreFilterType filter;
  final int requestId;
}
