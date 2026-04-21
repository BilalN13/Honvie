import 'package:flutter/foundation.dart';

import '../../../core/location/location_service.dart';
import '../../events/event_model.dart';
import '../../events/event_service.dart';
import '../../journal/models/checkin_record.dart';
import '../../places/data/fallback_places.dart';
import '../../places/data/google_places_service.dart';
import '../../places_user/user_place_service.dart';
import '../../recommendation/personalization_service.dart';
import '../../recommendation/recommendation_service.dart';
import '../../home/models/home_models.dart';

class ExplorePlacesResult {
  const ExplorePlacesResult({
    required this.centerLocation,
    required this.locationStatus,
    required this.places,
    required this.events,
    required this.usedFallbackPlaces,
    this.userLocation,
  });

  final AppLocation centerLocation;
  final AppLocationStatus locationStatus;
  final AppLocation? userLocation;
  final List<NearbyPlace> places;
  final List<EventItem> events;
  final bool usedFallbackPlaces;

  bool get hasUserLocation => userLocation != null;
}

class ExplorePlacesService {
  ExplorePlacesService._();

  static final ExplorePlacesService instance = ExplorePlacesService._();
  static const Duration _defaultLocationTimeout = Duration(seconds: 2);

  static const AppLocation _defaultCenter = AppLocation(
    latitude: FallbackPlaces.defaultLatitude,
    longitude: FallbackPlaces.defaultLongitude,
  );

  final LocationService _locationService = LocationService.instance;
  final GooglePlacesService _googlePlacesService = GooglePlacesService.instance;
  final UserPlaceService _userPlaceService = UserPlaceService.instance;
  final EventService _eventService = EventService.instance;
  final PersonalizationService _personalizationService =
      PersonalizationService.instance;

  Future<ExplorePlacesResult> fetchPlaces({
    required CheckinRecord? record,
    AppLocation? locationOverride,
    Duration locationTimeout = _defaultLocationTimeout,
  }) async {
    debugPrint(
      'ExplorePlacesService: starting Explorer places load. '
      'locationOverride=${locationOverride != null}, '
      'locationTimeout=${locationTimeout.inMilliseconds}ms.',
    );

    try {
      final personalizationFuture = _personalizationService.fetchProfile(
        forceRefresh: true,
      );

      final AppLocationResult locationResult;
      if (locationOverride != null) {
        locationResult = AppLocationResult(
          status: AppLocationStatus.available,
          location: locationOverride,
        );
      } else {
        locationResult = await _locationService.resolveCurrentLocation(
          overallTimeout: locationTimeout,
          positionTimeLimit: locationTimeout,
        );
      }

      final centerLocation = locationResult.location ?? _defaultCenter;

      final types = RecommendationService.instance.recommendedPlaceTypes(
        currentEmotion: record?.currentEmotion,
        desiredEmotion: record?.desiredEmotion,
        activity: record?.activity,
      );

      final results =
          await Future.wait<dynamic>(<Future<dynamic>>[
            _eventService.fetchNearbyEvents(
              lat: centerLocation.latitude,
              lng: centerLocation.longitude,
              currentEmotion: record?.currentEmotion,
              desiredEmotion: record?.desiredEmotion,
              activity: record?.activity,
            ),
            _googlePlacesService.fetchNearbyPlaces(
              lat: centerLocation.latitude,
              lng: centerLocation.longitude,
              includedTypes: types,
            ),
            _userPlaceService.fetchNearbyPlaces(
              latitude: centerLocation.latitude,
              longitude: centerLocation.longitude,
            ),
          ]).timeout(
            const Duration(seconds: 3),
            onTimeout: () {
              debugPrint(
                'ExplorePlacesService: nearby data load timed out. '
                'Falling back to local defaults.',
              );
              return <dynamic>[
                const <EventItem>[],
                const <NearbyPlace>[],
                const <NearbyPlace>[],
              ];
            },
          );

      final events = results[0] as List<EventItem>;
      final googlePlaces = results[1] as List<NearbyPlace>;
      final userPlaces = results[2] as List<NearbyPlace>;
      final usedFallbackPlaces = googlePlaces.isEmpty;
      final personalizationProfile = await personalizationFuture;

      final mergedPlaces = RecommendationService.instance.mergeAndRankPlaces(
        googlePlaces: usedFallbackPlaces ? FallbackPlaces.items : googlePlaces,
        userPlaces: userPlaces,
        currentEmotion: record?.currentEmotion,
        desiredEmotion: record?.desiredEmotion,
        activity: record?.activity,
        personalizationProfile: personalizationProfile,
      );

      debugPrint(
        'ExplorePlacesService: Explorer places load succeeded. '
        'locationStatus=${locationResult.status}, '
        'usedFallbackPlaces=$usedFallbackPlaces, '
        'placeCount=${mergedPlaces.length}, eventCount=${events.length}.',
      );

      return ExplorePlacesResult(
        centerLocation: centerLocation,
        locationStatus: locationResult.status,
        userLocation: locationResult.location,
        places: mergedPlaces,
        events: events,
        usedFallbackPlaces: usedFallbackPlaces,
      );
    } catch (error, stackTrace) {
      debugPrint(
        'ExplorePlacesService: Explorer places load failed. '
        'errorType=${error.runtimeType}.',
      );
      debugPrint('$error');
      debugPrint('$stackTrace');
      debugPrint(
        'ExplorePlacesService: fallback result returned after load failure.',
      );
      return _buildFallbackResult(
        locationStatus: locationOverride != null
            ? AppLocationStatus.available
            : AppLocationStatus.unavailable,
        userLocation: locationOverride,
      );
    }
  }

  ExplorePlacesResult _buildFallbackResult({
    AppLocationStatus locationStatus = AppLocationStatus.unavailable,
    AppLocation? userLocation,
  }) {
    return ExplorePlacesResult(
      centerLocation: userLocation ?? _defaultCenter,
      locationStatus: locationStatus,
      userLocation: userLocation,
      places: FallbackPlaces.items,
      events: const <EventItem>[],
      usedFallbackPlaces: true,
    );
  }
}
