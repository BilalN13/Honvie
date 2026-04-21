import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../../home/models/home_models.dart';
import '../place_metadata.dart';

class GooglePlacesService {
  GooglePlacesService._();

  static final GooglePlacesService instance = GooglePlacesService._();

  static const String _apiKey = String.fromEnvironment('GOOGLE_PLACES_API_KEY');
  static const String _endpoint =
      'https://places.googleapis.com/v1/places:searchNearby';
  static bool _didLogApiKeyState = false;

  Future<List<NearbyPlace>> fetchNearbyPlaces({
    required double lat,
    required double lng,
    required List<String> includedTypes,
  }) async {
    debugPrint(
      'GooglePlacesService: starting nearby places load. '
      'platform=${kIsWeb ? 'web' : defaultTargetPlatform.name}, '
      'center=($lat, $lng).',
    );
    _logApiKeyState();

    if (_apiKey.isEmpty) {
      debugPrint(
        'GooglePlacesService: missing GOOGLE_PLACES_API_KEY. '
        'Pass it with --dart-define=GOOGLE_PLACES_API_KEY=... for web/mobile.',
      );
      debugPrint(
        'GooglePlacesService: fallback used because the runtime Places key is absent.',
      );
      return const <NearbyPlace>[];
    }

    final googleTypes = _mapToGoogleTypes(includedTypes);
    if (googleTypes.isEmpty) {
      debugPrint(
        'GooglePlacesService: no supported Google place types to query.',
      );
      debugPrint(
        'GooglePlacesService: fallback used because no compatible Places types were requested.',
      );
      return const <NearbyPlace>[];
    }

    debugPrint(
      'GooglePlacesService: API call launched with center lat=$lat, lng=$lng '
      'and types ${googleTypes.join(', ')}.',
    );

    try {
      final uri = Uri.parse(_endpoint);
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': _apiKey,
        'X-Goog-FieldMask':
            'places.displayName,places.location,places.primaryType,places.types',
      };
      final payload = jsonEncode(<String, dynamic>{
        'includedTypes': googleTypes,
        'maxResultCount': 12,
        'locationRestriction': <String, dynamic>{
          'circle': <String, dynamic>{
            'center': <String, double>{'latitude': lat, 'longitude': lng},
            'radius': 3000,
          },
        },
      });

      final response = await http
          .post(uri, headers: headers, body: payload)
          .timeout(const Duration(seconds: 6));
      final responseBody = response.body;

      debugPrint(
        'GooglePlacesService: Places API HTTP response received with '
        'status=${response.statusCode}.',
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        debugPrint(
          'GooglePlacesService: Nearby Search failed with status ${response.statusCode}.',
        );
        debugPrint(responseBody);
        debugPrint(
          'GooglePlacesService: fallback used because the Places API request failed.',
        );
        return const <NearbyPlace>[];
      }

      final json = jsonDecode(responseBody) as Map<String, dynamic>;
      final rawPlaces = json['places'] as List<dynamic>? ?? const <dynamic>[];
      debugPrint(
        'GooglePlacesService: ${rawPlaces.length} raw places received from Places API.',
      );

      final places = rawPlaces
          .whereType<Map<String, dynamic>>()
          .map((Map<String, dynamic> place) => _mapPlace(place, lat, lng))
          .whereType<NearbyPlace>()
          .toList();

      debugPrint(
        'GooglePlacesService: Nearby Search succeeded with ${places.length} mapped places.',
      );
      if (places.isEmpty) {
        debugPrint(
          'GooglePlacesService: fallback used because the Places API returned no usable places.',
        );
      }

      return places;
    } catch (error, stackTrace) {
      debugPrint(
        'GooglePlacesService: failed to fetch nearby places. '
        'errorType=${error.runtimeType}.',
      );
      debugPrint('$error');
      debugPrint('$stackTrace');
      debugPrint(
        'GooglePlacesService: fallback used because the Places API call threw an exception.',
      );
      return const <NearbyPlace>[];
    }
  }

  void _logApiKeyState() {
    if (_didLogApiKeyState) {
      return;
    }

    _didLogApiKeyState = true;

    if (_apiKey.isEmpty) {
      debugPrint(
        'GooglePlacesService: GOOGLE_PLACES_API_KEY absent at runtime.',
      );
      return;
    }

    debugPrint(
      'GooglePlacesService: GOOGLE_PLACES_API_KEY present via --dart-define.',
    );
  }

  NearbyPlace? _mapPlace(
    Map<String, dynamic> place,
    double userLatitude,
    double userLongitude,
  ) {
    final displayName = place['displayName'] as Map<String, dynamic>?;
    final location = place['location'] as Map<String, dynamic>?;
    final name = displayName?['text'] as String?;
    final latitude = (location?['latitude'] as num?)?.toDouble();
    final longitude = (location?['longitude'] as num?)?.toDouble();

    if (name == null || latitude == null || longitude == null) {
      return null;
    }

    final primaryType = place['primaryType'] as String?;
    final rawTypes = (place['types'] as List<dynamic>? ?? const <dynamic>[])
        .map((dynamic item) => item.toString())
        .toList();
    final internalTypes = _mapToInternalTypes(primaryType, rawTypes);
    final distanceKm =
        Geolocator.distanceBetween(
          userLatitude,
          userLongitude,
          latitude,
          longitude,
        ) /
        1000;

    return NearbyPlace(
      name: name,
      distance: _formatDistance(distanceKm),
      category: PlaceMetadata.categoryLabel(
        primaryType: primaryType,
        internalTypes: internalTypes,
      ),
      icon: PlaceMetadata.iconForTypes(internalTypes),
      types: internalTypes,
      latitude: latitude,
      longitude: longitude,
      distanceKm: distanceKm,
    );
  }

  List<String> _mapToGoogleTypes(List<String> types) {
    final mapped = <String>[];

    for (final type in types) {
      switch (type) {
        case 'cafe':
        case 'cafe calme':
          mapped.add('cafe');
          break;
        case 'parc':
        case 'nature':
          mapped.add('park');
          break;
        case 'musee':
          mapped.add('museum');
          break;
        case 'expo':
        case 'atelier':
          mapped.add('art_gallery');
          break;
        case 'librairie':
          mapped.add('book_store');
          break;
        case 'cinema':
          mapped.add('movie_theater');
          break;
        case 'bar':
          mapped.add('bar');
          break;
        case 'evenement':
        case 'bord de mer':
          mapped.add('tourist_attraction');
          break;
      }
    }

    return mapped.toSet().toList();
  }

  List<String> _mapToInternalTypes(String? primaryType, List<String> rawTypes) {
    final allTypes = <String>{...rawTypes};
    if (primaryType != null) {
      allTypes.add(primaryType);
    }

    final internal = <String>{};

    for (final type in allTypes) {
      switch (type) {
        case 'cafe':
          internal.addAll(<String>['cafe', 'cafe calme']);
          break;
        case 'park':
          internal.addAll(<String>['parc', 'nature']);
          break;
        case 'museum':
          internal.add('musee');
          break;
        case 'art_gallery':
          internal.addAll(<String>['expo', 'atelier']);
          break;
        case 'book_store':
          internal.add('librairie');
          break;
        case 'movie_theater':
          internal.add('cinema');
          break;
        case 'bar':
          internal.add('bar');
          break;
        case 'tourist_attraction':
          internal.addAll(<String>['evenement', 'bord de mer']);
          break;
      }
    }

    if (internal.isEmpty) {
      internal.add('cafe');
    }

    return internal.toList();
  }

  String _formatDistance(double distanceKm) {
    if (distanceKm < 1) {
      final meters = (distanceKm * 1000).round();
      return '$meters m';
    }

    return '${distanceKm.toStringAsFixed(1)} km';
  }
}
