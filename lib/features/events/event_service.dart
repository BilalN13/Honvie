import 'package:geolocator/geolocator.dart';

import 'event_model.dart';

class EventService {
  EventService._();

  static final EventService instance = EventService._();

  Future<List<EventItem>> fetchNearbyEvents({
    required double lat,
    required double lng,
    required String? currentEmotion,
    required String? desiredEmotion,
    required String? activity,
    double maxDistanceKm = 3,
    Duration within = const Duration(hours: 48),
  }) async {
    final now = DateTime.now();
    final mockEvents = _buildMockEvents(now);
    final horizon = now.add(within);

    final events = mockEvents
        .map((_RawEvent event) {
          final eventLat = lat + event.latOffset;
          final eventLng = lng + event.lngOffset;
          final distanceKm =
              Geolocator.distanceBetween(lat, lng, eventLat, eventLng) / 1000;

          return EventItem(
            title: event.title,
            locationName: event.locationName,
            dateTime: event.dateTime,
            category: event.category,
            distanceKm: distanceKm,
            latitude: eventLat,
            longitude: eventLng,
          );
        })
        .where((EventItem event) {
          final isNearby = event.distanceKm <= maxDistanceKm;
          final isUpcoming = event.dateTime.isAfter(now);
          final isWithinWindow =
              event.dateTime.isBefore(horizon) ||
              event.dateTime.isAtSameMomentAs(horizon);
          return isNearby && isUpcoming && isWithinWindow;
        })
        .map((EventItem event) {
          return _scoreEvent(
            event,
            currentEmotion: currentEmotion,
            desiredEmotion: desiredEmotion,
            activity: activity,
          );
        })
        .toList();

    events.sort((EventItem left, EventItem right) {
      final byScore = right.recommendationScore.compareTo(
        left.recommendationScore,
      );
      if (byScore != 0) {
        return byScore;
      }

      final byDate = left.dateTime.compareTo(right.dateTime);
      if (byDate != 0) {
        return byDate;
      }

      return left.distanceKm.compareTo(right.distanceKm);
    });

    final hasContextualMatch = events.any((EventItem event) {
      return event.recommendationScore >= 4;
    });

    if (!hasContextualMatch) {
      events.sort((EventItem left, EventItem right) {
        final byDistance = left.distanceKm.compareTo(right.distanceKm);
        if (byDistance != 0) {
          return byDistance;
        }

        return left.dateTime.compareTo(right.dateTime);
      });
    }

    return events;
  }

  EventItem _scoreEvent(
    EventItem event, {
    required String? currentEmotion,
    required String? desiredEmotion,
    required String? activity,
  }) {
    final desiredCategories = _desiredEmotionCategories(desiredEmotion);
    final activityCategories = _activityCategories(activity);
    final currentCategories = _currentEmotionCategories(currentEmotion);
    final normalizedCategory = event.category.toLowerCase();

    final desiredMatched = desiredCategories.contains(normalizedCategory);
    final activityMatched = activityCategories.contains(normalizedCategory);
    final currentMatched = currentCategories.contains(normalizedCategory);

    var score = 0;
    if (desiredMatched) {
      score += 4;
    }
    if (activityMatched) {
      score += 3;
    }
    if (currentMatched) {
      score += 1;
    }

    if (event.distanceKm < 1) {
      score += 2;
    } else if (event.distanceKm < 3) {
      score += 1;
    }

    return event.copyWith(
      recommendationScore: score,
      recommendationReason: _buildReason(
        desiredEmotion: desiredEmotion,
        activity: activity,
        desiredMatched: desiredMatched,
        activityMatched: activityMatched,
        currentMatched: currentMatched,
        distanceKm: event.distanceKm,
      ),
    );
  }

  String _buildReason({
    required String? desiredEmotion,
    required String? activity,
    required bool desiredMatched,
    required bool activityMatched,
    required bool currentMatched,
    required double distanceKm,
  }) {
    if (desiredMatched) {
      switch (desiredEmotion) {
        case 'social':
          return 'Bien aligne avec ton envie de lien';
        case 'pose':
          return 'Correspond a ton besoin de calme';
        case 'creatif':
          return 'Soutient ton elan creatif';
        case 'curieux':
          return 'Nourrit ton envie de decouverte';
        case 'motive':
          return 'Peut relancer ton energie';
        case 'introspectif':
          return 'Convient a un moment plus interieur';
      }
    }

    if (activityMatched) {
      switch (activity) {
        case 'marcher':
          return 'Une sortie simple a faire aujourd hui';
        case 'musee':
          return 'Bonne option pour changer d ambiance';
        case 'lecture':
          return 'Prolonge bien une envie de lecture';
        case 'ecrire':
          return 'Peut inspirer un moment pour ecrire';
        case 'cinema':
          return 'Ideal pour une vraie pause';
        case 'respiration':
          return 'Une ambiance plus douce pour ralentir';
      }
    }

    if (distanceKm < 1) {
      return 'Pres de toi';
    }

    if (currentMatched) {
      return 'Coherent avec ton ressenti du moment';
    }

    return 'Option accessible aujourd hui';
  }

  List<String> _desiredEmotionCategories(String? desiredEmotion) {
    switch (desiredEmotion) {
      case 'social':
        return const <String>['concert', 'meetup', 'soiree'];
      case 'pose':
        return const <String>['yoga', 'expo', 'lecture'];
      case 'creatif':
        return const <String>['atelier', 'expo', 'peinture'];
      case 'curieux':
        return const <String>['expo', 'atelier', 'conference'];
      case 'motive':
        return const <String>['meetup', 'atelier', 'conference'];
      case 'introspectif':
        return const <String>['lecture', 'expo', 'yoga'];
      default:
        return const <String>[];
    }
  }

  List<String> _activityCategories(String? activity) {
    switch (activity) {
      case 'marcher':
        return const <String>['meetup', 'expo'];
      case 'musee':
        return const <String>['expo'];
      case 'lecture':
        return const <String>['lecture'];
      case 'ecrire':
        return const <String>['atelier', 'lecture'];
      case 'cinema':
        return const <String>['cinema'];
      case 'respiration':
        return const <String>['yoga'];
      case 'pause gourmande':
        return const <String>['meetup', 'concert'];
      default:
        return const <String>[];
    }
  }

  List<String> _currentEmotionCategories(String? currentEmotion) {
    switch (currentEmotion) {
      case 'enerve':
        return const <String>['yoga', 'lecture', 'expo'];
      case 'triste':
        return const <String>['lecture', 'expo', 'yoga'];
      case 'neutre':
        return const <String>['expo', 'atelier'];
      case 'content':
        return const <String>['meetup', 'expo'];
      case 'joyeux':
        return const <String>['concert', 'meetup', 'soiree'];
      default:
        return const <String>[];
    }
  }

  // Kept isolated so the home section can later switch to a real API without
  // changing the filtering, scoring and sorting pipeline.
  List<_RawEvent> _buildMockEvents(DateTime now) {
    return <_RawEvent>[
      _RawEvent(
        title: 'Concert acoustique',
        locationName: 'Quiet Cafe',
        latOffset: 0.0042,
        lngOffset: 0.0020,
        dateTime: now.add(const Duration(hours: 5)),
        category: 'Concert',
      ),
      _RawEvent(
        title: 'Visite d expo photo',
        locationName: 'Museum Hall',
        latOffset: 0.0080,
        lngOffset: -0.0040,
        dateTime: now.add(const Duration(hours: 12)),
        category: 'Expo',
      ),
      _RawEvent(
        title: 'Atelier carnet creatif',
        locationName: 'Art Studio',
        latOffset: -0.0035,
        lngOffset: 0.0050,
        dateTime: now.add(const Duration(hours: 20)),
        category: 'Atelier',
      ),
      _RawEvent(
        title: 'Projection plein air',
        locationName: 'Cinema Nova',
        latOffset: 0.0100,
        lngOffset: 0.0060,
        dateTime: now.add(const Duration(hours: 28)),
        category: 'Cinema',
      ),
      _RawEvent(
        title: 'Lecture collective',
        locationName: 'Page Corner',
        latOffset: -0.0028,
        lngOffset: -0.0020,
        dateTime: now.add(const Duration(hours: 34)),
        category: 'Lecture',
      ),
      _RawEvent(
        title: 'Pause yoga au parc',
        locationName: 'City Park',
        latOffset: 0.0030,
        lngOffset: -0.0015,
        dateTime: now.add(const Duration(hours: 16)),
        category: 'Yoga',
      ),
      _RawEvent(
        title: 'Grande scene de quartier',
        locationName: 'Central Arena',
        latOffset: 0.0300,
        lngOffset: 0.0180,
        dateTime: now.add(const Duration(hours: 10)),
        category: 'Concert',
      ),
      _RawEvent(
        title: 'Rencontre bien-etre',
        locationName: 'Social House',
        latOffset: 0.0040,
        lngOffset: -0.0030,
        dateTime: now.add(const Duration(hours: 22)),
        category: 'Meetup',
      ),
    ];
  }
}

class _RawEvent {
  const _RawEvent({
    required this.title,
    required this.locationName,
    required this.latOffset,
    required this.lngOffset,
    required this.dateTime,
    required this.category,
  });

  final String title;
  final String locationName;
  final double latOffset;
  final double lngOffset;
  final DateTime dateTime;
  final String category;
}
