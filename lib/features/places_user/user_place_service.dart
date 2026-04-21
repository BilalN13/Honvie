import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../home/models/home_models.dart';
import '../places/place_metadata.dart';
import 'user_place_model.dart';

class UserPlaceService {
  UserPlaceService._();

  static final UserPlaceService instance = UserPlaceService._();

  static const String _tableName = 'user_places';
  static const String _publicPlacesRpc = 'get_public_user_places';
  static const double _sameNameMergeDistanceMeters = 350;
  static const double _nearbyMergeDistanceMeters = 120;

  SupabaseClient? get _clientOrNull {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  Future<String?> _ensureUserId(SupabaseClient? client) async {
    if (client == null) {
      return null;
    }

    final currentUser = client.auth.currentUser;
    if (currentUser != null && !currentUser.isAnonymous) {
      return currentUser.id;
    }

    return null;
  }

  Future<UserPlace> savePlace(UserPlaceDraft draft) async {
    final client = _clientOrNull;
    final userId = await _ensureUserId(client);

    if (client == null || userId == null) {
      throw StateError('Supabase authentication unavailable.');
    }

    final response = await client
        .from(_tableName)
        .insert(draft.toSupabaseInsert(userId: userId))
        .select()
        .single();

    return UserPlace.fromSupabase(response);
  }

  Future<List<UserPlace>> fetchUserPlaces() async {
    final client = _clientOrNull;
    final userId = await _ensureUserId(client);

    if (client == null || userId == null) {
      return const <UserPlace>[];
    }

    try {
      final response = await client
          .from(_tableName)
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(UserPlace.fromSupabase)
          .toList();
    } catch (_) {
      return const <UserPlace>[];
    }
  }

  Future<List<NearbyPlace>> fetchNearbyPlaces({
    required double latitude,
    required double longitude,
    double maxDistanceKm = 5,
  }) async {
    final places = await _fetchPlacesForAggregation();
    final clusters = _clusterPlaces(
      places,
      userLatitude: latitude,
      userLongitude: longitude,
    );

    return clusters
        .map(
          (_UserPlaceCluster cluster) => _toNearbyPlace(
            cluster,
            userLatitude: latitude,
            userLongitude: longitude,
          ),
        )
        .where((NearbyPlace place) => (place.distanceKm ?? 99) <= maxDistanceKm)
        .toList();
  }

  Future<List<PublicUserPlace>> _fetchPlacesForAggregation() async {
    final client = _clientOrNull;

    if (client == null) {
      debugPrint(
        'UserPlaceService: Supabase client unavailable while fetching public '
        'user places. Social proof aggregation cannot run.',
      );
      return const <PublicUserPlace>[];
    }

    try {
      final response = await client.rpc(_publicPlacesRpc);

      return (response as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(PublicUserPlace.fromSupabase)
          .toList();
    } catch (error, stackTrace) {
      debugPrint(
        'UserPlaceService: RPC get_public_user_places unavailable. This may '
        'depend on the Supabase migration '
        '20260412_create_public_user_places_rpc.sql. Falling back to current '
        'user places only for aggregation.',
      );
      debugPrint('$error');
      debugPrint('$stackTrace');

      final ownPlaces = await fetchUserPlaces();
      return ownPlaces
          .map(
            (UserPlace place) => PublicUserPlace(
              name: place.name,
              type: place.type,
              moodTags: place.moodTags,
              latitude: place.latitude,
              longitude: place.longitude,
              createdAt: place.createdAt,
            ),
          )
          .toList();
    }
  }

  List<_UserPlaceCluster> _clusterPlaces(
    List<PublicUserPlace> places, {
    required double userLatitude,
    required double userLongitude,
  }) {
    final orderedPlaces = List<PublicUserPlace>.from(places)
      ..sort(
        (PublicUserPlace left, PublicUserPlace right) =>
            right.createdAt.compareTo(left.createdAt),
      );

    final clusters = <_UserPlaceCluster>[];

    for (final place in orderedPlaces) {
      _UserPlaceCluster? matchingCluster;

      for (final cluster in clusters) {
        if (_shouldMerge(cluster, place)) {
          matchingCluster = cluster;
          break;
        }
      }

      if (matchingCluster == null) {
        clusters.add(_UserPlaceCluster.fromPlace(place));
      } else {
        matchingCluster.add(place);
      }
    }

    clusters.sort((_UserPlaceCluster left, _UserPlaceCluster right) {
      final byDistance =
          Geolocator.distanceBetween(
            userLatitude,
            userLongitude,
            left.representativeLatitude,
            left.representativeLongitude,
          ).compareTo(
            Geolocator.distanceBetween(
              userLatitude,
              userLongitude,
              right.representativeLatitude,
              right.representativeLongitude,
            ),
          );
      if (byDistance != 0) {
        return byDistance;
      }

      return right.addedCount.compareTo(left.addedCount);
    });

    return clusters;
  }

  bool _shouldMerge(_UserPlaceCluster cluster, PublicUserPlace place) {
    final sameName =
        cluster.normalizedNames.contains(_normalizeName(place.name)) &&
        cluster.distanceTo(place) <= _sameNameMergeDistanceMeters;

    if (sameName) {
      return true;
    }

    return cluster.distanceTo(place) <= _nearbyMergeDistanceMeters;
  }

  NearbyPlace _toNearbyPlace(
    _UserPlaceCluster place, {
    required double userLatitude,
    required double userLongitude,
  }) {
    final internalTypes = PlaceMetadata.expandInternalTypes(place.type);
    final distanceKm =
        Geolocator.distanceBetween(
          userLatitude,
          userLongitude,
          place.representativeLatitude,
          place.representativeLongitude,
        ) /
        1000;

    return NearbyPlace(
      id: place.clusterId,
      name: place.name,
      distance: _formatDistance(distanceKm),
      category: PlaceMetadata.categoryLabel(internalTypes: internalTypes),
      icon: PlaceMetadata.iconForTypes(internalTypes),
      types: internalTypes,
      moodTags: place.sortedMoodTags,
      isUserPlace: true,
      isUserAdded: true,
      socialProofCount: place.addedCount,
      popularMoodTag: place.popularMoodTag,
      latitude: place.representativeLatitude,
      longitude: place.representativeLongitude,
      distanceKm: distanceKm,
    );
  }

  String _formatDistance(double distanceKm) {
    if (distanceKm < 1) {
      final meters = (distanceKm * 1000).round();
      return '$meters m';
    }

    return '${distanceKm.toStringAsFixed(1)} km';
  }

  String _normalizeName(String value) {
    return value.trim().toLowerCase();
  }
}

class _UserPlaceCluster {
  _UserPlaceCluster({
    required List<PublicUserPlace> places,
    required Map<String, int> nameCounts,
    required Map<String, int> typeCounts,
    required Map<String, int> moodCounts,
    required this.normalizedNames,
  }) : _places = places,
       _nameCounts = nameCounts,
       _typeCounts = typeCounts,
       _moodCounts = moodCounts;

  factory _UserPlaceCluster.fromPlace(PublicUserPlace place) {
    final cluster = _UserPlaceCluster(
      places: <PublicUserPlace>[],
      nameCounts: <String, int>{},
      typeCounts: <String, int>{},
      moodCounts: <String, int>{},
      normalizedNames: <String>{},
    );
    cluster.add(place);
    return cluster;
  }

  final List<PublicUserPlace> _places;
  final Map<String, int> _nameCounts;
  final Map<String, int> _typeCounts;
  final Map<String, int> _moodCounts;
  final Set<String> normalizedNames;

  void add(PublicUserPlace place) {
    _places.add(place);
    normalizedNames.add(place.name.trim().toLowerCase());
    _nameCounts.update(place.name, (int count) => count + 1, ifAbsent: () => 1);
    _typeCounts.update(place.type, (int count) => count + 1, ifAbsent: () => 1);

    for (final moodTag in place.moodTags) {
      _moodCounts.update(moodTag, (int count) => count + 1, ifAbsent: () => 1);
    }
  }

  int get addedCount => _places.length;

  String get name => _mostFrequentKey(_nameCounts);

  String get type => _mostFrequentKey(_typeCounts);

  String get clusterId =>
      '${name.toLowerCase()}-${representativeLatitude.toStringAsFixed(5)}-${representativeLongitude.toStringAsFixed(5)}';

  String? get popularMoodTag {
    if (_moodCounts.isEmpty) {
      return null;
    }

    return _sortedMoodEntries.first.key;
  }

  List<String> get sortedMoodTags {
    return _sortedMoodEntries
        .map((MapEntry<String, int> entry) => entry.key)
        .toList();
  }

  double get representativeLatitude => _places.first.latitude;

  double get representativeLongitude => _places.first.longitude;

  double distanceTo(PublicUserPlace place) {
    return Geolocator.distanceBetween(
      representativeLatitude,
      representativeLongitude,
      place.latitude,
      place.longitude,
    );
  }

  String _mostFrequentKey(Map<String, int> counts) {
    final ordered = counts.entries.toList()
      ..sort((MapEntry<String, int> left, MapEntry<String, int> right) {
        final byCount = right.value.compareTo(left.value);
        if (byCount != 0) {
          return byCount;
        }

        return left.key.toLowerCase().compareTo(right.key.toLowerCase());
      });

    return ordered.first.key;
  }

  List<MapEntry<String, int>> get _sortedMoodEntries {
    final entries = _moodCounts.entries.toList()
      ..sort((MapEntry<String, int> left, MapEntry<String, int> right) {
        final byCount = right.value.compareTo(left.value);
        if (byCount != 0) {
          return byCount;
        }

        return left.key.compareTo(right.key);
      });

    return entries;
  }
}
