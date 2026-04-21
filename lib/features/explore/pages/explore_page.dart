import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/location/location_service.dart';
import '../../../core/maps/google_maps_launcher.dart';
import '../../../core/maps/google_maps_web_runtime.dart';
import '../../../core/theme/app_colors.dart';
import '../../checkin/data/checkin_service.dart';
import '../../checkin/widgets/place_journal_actions.dart';
import '../../checkin/widgets/place_note_dialog.dart';
import '../../events/event_model.dart';
import '../models/explore_navigation_models.dart';
import '../../home/models/home_models.dart';
import '../../journal/controllers/local_checkin_store.dart';
import '../../journal/models/checkin_record.dart';
import '../../places/data/fallback_places.dart';
import '../../places/place_metadata.dart';
import '../../recommendation/personalization_service.dart';
import '../../recommendation/recommendation_service.dart';
import '../data/explore_places_service.dart';
import '../map/explore_marker_factory.dart';

enum _ExploreMapState { loading, ready, fallback, error }

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key, this.requestListenable});

  final ValueListenable<ExploreViewRequest?>? requestListenable;

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  static const String _exploreMapStyle = '''
[
  {
    "featureType": "poi",
    "elementType": "labels.icon",
    "stylers": [{"visibility": "off"}]
  },
  {
    "featureType": "poi.business",
    "stylers": [{"visibility": "off"}]
  },
  {
    "featureType": "transit",
    "elementType": "labels.icon",
    "stylers": [{"visibility": "off"}]
  }
]
''';

  final LocalCheckinStore _store = LocalCheckinStore.instance;
  final ExplorePlacesService _service = ExplorePlacesService.instance;
  final LocationService _locationService = LocationService.instance;
  final CheckinService _checkinService = CheckinService.instance;
  final PersonalizationService _personalizationService =
      PersonalizationService.instance;
  final GoogleMapsWebRuntime _webMapsRuntime = createGoogleMapsWebRuntime();
  final Completer<GoogleMapController> _mapControllerCompleter =
      Completer<GoogleMapController>();
  final Map<String, BitmapDescriptor> _markerIconCache =
      <String, BitmapDescriptor>{};
  final BitmapDescriptor _fallbackUserPlaceMarkerIcon =
      BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose);
  final BitmapDescriptor _fallbackRecommendedPlaceMarkerIcon =
      BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
  final BitmapDescriptor _fallbackDefaultPlaceMarkerIcon =
      BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose);
  final BitmapDescriptor _fallbackTopRecommendationMarkerIcon =
      BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
  final BitmapDescriptor _fallbackEventMarkerIcon =
      BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);

  static const LatLng _defaultLatLng = LatLng(
    FallbackPlaces.defaultLatitude,
    FallbackPlaces.defaultLongitude,
  );

  ExplorePlacesResult? _result;
  bool _isLoading = true;
  String _recommendationKey = '';
  ExploreFilterType _activeFilter = ExploreFilterType.all;
  _ExploreMapState _mapState = _ExploreMapState.loading;
  String? _mapStateReason;
  bool _didLogWebMapsState = false;
  Timer? _webMapsRetryTimer;
  Timer? _mapInitTimeoutTimer;
  int _webMapsRetryCount = 0;
  int _lastHandledRequestId = 0;
  int _locationRecoveryGeneration = 0;
  bool _isRecoveringUserLocation = false;

  @override
  void initState() {
    super.initState();
    _store.addListener(_handleStoreChanged);
    widget.requestListenable?.addListener(_handleExternalNavigationRequest);
    _startWebMapsAvailabilityPolling();
    _syncMapState(source: 'init');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_preloadMarkerIcons());
      _refreshPlaces(force: true);
    });
  }

  @override
  void didUpdateWidget(covariant ExplorePage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.requestListenable == widget.requestListenable) {
      return;
    }

    oldWidget.requestListenable?.removeListener(
      _handleExternalNavigationRequest,
    );
    widget.requestListenable?.addListener(_handleExternalNavigationRequest);
  }

  @override
  void dispose() {
    _webMapsRetryTimer?.cancel();
    _mapInitTimeoutTimer?.cancel();
    widget.requestListenable?.removeListener(_handleExternalNavigationRequest);
    _store.removeListener(_handleStoreChanged);
    super.dispose();
  }

  void _handleStoreChanged() {
    final record = _recommendationRecord;
    final nextKey = _buildRecommendationKey(record);
    if (nextKey == _recommendationKey) {
      return;
    }

    _applyLocalRecommendationUpdate(record);
    _refreshPlaces();
  }

  void _handleExternalNavigationRequest() {
    final request = widget.requestListenable?.value;
    if (request == null || request.requestId == _lastHandledRequestId) {
      return;
    }

    _lastHandledRequestId = request.requestId;
    unawaited(_applyRequestedFilter(request.filter));
  }

  Future<void> _applyRequestedFilter(ExploreFilterType filter) async {
    if (!mounted) {
      return;
    }

    if (_activeFilter != filter) {
      setState(() {
        _activeFilter = filter;
      });
    }

    final result = _result;
    if (result == null || !_supportsInteractiveMap) {
      return;
    }

    await _updateMapViewport(
      places: _visiblePlaces(result.places),
      events: _visibleEvents(result.events),
      fallbackLocation: result.centerLocation,
    );
  }

  void _startWebMapsAvailabilityPolling() {
    if (!kIsWeb || _webMapsRuntime.isScriptAvailable) {
      return;
    }

    _webMapsRetryTimer = Timer.periodic(const Duration(milliseconds: 400), (
      Timer timer,
    ) {
      _webMapsRetryCount += 1;

      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_webMapsRuntime.isScriptAvailable) {
        debugPrint(
          'ExplorePage: Google Maps web script became available after initial fallback.',
        );
        timer.cancel();
        setState(() {
          _didLogWebMapsState = false;
        });
        _syncMapState(source: 'web_script_available');
        return;
      }

      if (_webMapsRetryCount >= 8) {
        timer.cancel();
        _syncMapState(source: 'web_script_unavailable_after_retry');
      }
    });
  }

  Future<void> _refreshPlaces({bool force = false}) async {
    final record = _recommendationRecord;
    final nextKey = _buildRecommendationKey(record);

    if (!force && nextKey == _recommendationKey) {
      return;
    }

    final refreshGeneration = ++_locationRecoveryGeneration;
    debugPrint(
      'ExplorePage: starting Explorer load. force=$force, '
      'requestKey=$nextKey, refreshGeneration=$refreshGeneration.',
    );

    _recommendationKey = nextKey;

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final result = await _service.fetchPlaces(record: record);
      if (!mounted || _recommendationKey != nextKey) {
        return;
      }

      await _prepareMarkerIcons(places: result.places, events: result.events);
      if (!mounted || _recommendationKey != nextKey) {
        return;
      }

      setState(() {
        _result = result;
        _isLoading = false;
        _isRecoveringUserLocation = false;
      });

      if (result.usedFallbackPlaces) {
        debugPrint(
          'ExplorePage: places fallback used. placeCount=${result.places.length}, '
          'eventCount=${result.events.length}.',
        );
      } else {
        debugPrint(
          'ExplorePage: places loaded from API. placeCount=${result.places.length}, '
          'eventCount=${result.events.length}.',
        );
      }

      _syncMapState(source: 'places_loaded');

      if (_supportsInteractiveMap) {
        await _updateMapViewport(
          places: _visiblePlaces(result.places),
          events: _visibleEvents(result.events),
          fallbackLocation: result.centerLocation,
        );
      }

      debugPrint('ExplorePage: Explorer load completed successfully.');

      unawaited(
        _maybeRecoverUserLocation(
          result: result,
          record: record,
          refreshGeneration: refreshGeneration,
        ),
      );
    } catch (error, stackTrace) {
      debugPrint(
        'ExplorePage: Explorer load failed unexpectedly. '
        'errorType=${error.runtimeType}.',
      );
      debugPrint('$error');
      debugPrint('$stackTrace');

      if (!mounted || _recommendationKey != nextKey) {
        return;
      }

      setState(() {
        _isLoading = false;
        _isRecoveringUserLocation = false;
      });

      _syncMapState(source: 'places_load_failed');
    }
  }

  CheckinRecord? get _recommendationRecord {
    return _store.todayRecord ?? _store.latestSavedRecord;
  }

  void _applyLocalRecommendationUpdate(CheckinRecord? record) {
    final currentResult = _result;
    if (currentResult == null || !mounted) {
      return;
    }

    final rerankedPlaces = RecommendationService.instance.rankPlaces(
      places: currentResult.places,
      currentEmotion: record?.currentEmotion,
      desiredEmotion: record?.desiredEmotion,
      activity: record?.activity,
      personalizationProfile: _personalizationService.currentProfile,
    );

    final updatedResult = ExplorePlacesResult(
      centerLocation: currentResult.centerLocation,
      locationStatus: currentResult.locationStatus,
      userLocation: currentResult.userLocation,
      places: rerankedPlaces,
      events: currentResult.events,
      usedFallbackPlaces: currentResult.usedFallbackPlaces,
    );

    setState(() {
      _result = updatedResult;
    });

    unawaited(
      _prepareMarkerIcons(places: rerankedPlaces, events: currentResult.events),
    );

    if (_supportsInteractiveMap) {
      unawaited(
        _updateMapViewport(
          places: _visiblePlaces(rerankedPlaces),
          events: _visibleEvents(currentResult.events),
          fallbackLocation: currentResult.centerLocation,
        ),
      );
    }
  }

  Future<void> _maybeRecoverUserLocation({
    required ExplorePlacesResult result,
    required CheckinRecord? record,
    required int refreshGeneration,
  }) async {
    if (!kIsWeb ||
        result.hasUserLocation ||
        result.locationStatus != AppLocationStatus.unavailable ||
        _isRecoveringUserLocation) {
      return;
    }

    debugPrint(
      'ExplorePage: starting delayed web user-location recovery after fallback.',
    );

    if (mounted) {
      setState(() {
        _isRecoveringUserLocation = true;
      });
    } else {
      _isRecoveringUserLocation = true;
    }

    final locationResult = await _locationService.resolveCurrentLocation(
      overallTimeout: const Duration(seconds: 12),
      positionTimeLimit: const Duration(seconds: 12),
    );

    if (!mounted || refreshGeneration != _locationRecoveryGeneration) {
      return;
    }

    if (locationResult.status != AppLocationStatus.available ||
        locationResult.location == null) {
      debugPrint(
        'ExplorePage: delayed web user-location recovery failed. '
        'status=${locationResult.status}.',
      );
      _applyRecoveredLocationFailure(locationResult);
      return;
    }

    final recoveredLocation = locationResult.location!;
    debugPrint(
      'ExplorePage: delayed web user-location recovery succeeded. '
      'lat=${recoveredLocation.latitude}, lng=${recoveredLocation.longitude}.',
    );

    final refreshedResult = await _service.fetchPlaces(
      record: record,
      locationOverride: recoveredLocation,
    );

    if (!mounted || refreshGeneration != _locationRecoveryGeneration) {
      return;
    }

    await _prepareMarkerIcons(
      places: refreshedResult.places,
      events: refreshedResult.events,
    );
    if (!mounted || refreshGeneration != _locationRecoveryGeneration) {
      return;
    }

    setState(() {
      _result = refreshedResult;
      _isRecoveringUserLocation = false;
    });

    await _animateCameraTo(recoveredLocation);
  }

  void _applyRecoveredLocationFailure(AppLocationResult locationResult) {
    final currentResult = _result;
    if (!mounted || currentResult == null) {
      _isRecoveringUserLocation = false;
      return;
    }

    setState(() {
      _result = ExplorePlacesResult(
        centerLocation: currentResult.centerLocation,
        locationStatus: locationResult.status,
        userLocation: locationResult.location,
        places: currentResult.places,
        events: currentResult.events,
        usedFallbackPlaces: currentResult.usedFallbackPlaces,
      );
      _isRecoveringUserLocation = false;
    });
  }

  Future<void> _animateCameraTo(AppLocation location) async {
    if (!_mapControllerCompleter.isCompleted) {
      return;
    }

    final controller = await _mapControllerCompleter.future;
    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(location.latitude, location.longitude),
          zoom: 13.7,
        ),
      ),
    );
  }

  bool get _supportsInteractiveMap {
    final bindingName = WidgetsBinding.instance.runtimeType.toString();
    final isWidgetTest = bindingName.contains('TestWidgetsFlutterBinding');
    if (isWidgetTest) {
      return false;
    }

    if (kIsWeb) {
      return _webMapsRuntime.isScriptAvailable;
    }

    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  bool get _showsInteractiveMap {
    return _supportsInteractiveMap &&
        _mapState != _ExploreMapState.fallback &&
        _mapState != _ExploreMapState.error;
  }

  Set<Marker> _buildMarkers({
    required List<NearbyPlace> places,
    required List<EventItem> events,
    NearbyPlace? topRecommendedPlace,
  }) {
    return <Marker>{
      ..._buildPlaceMarkers(places, topRecommendedPlace: topRecommendedPlace),
      ..._buildEventMarkers(events),
    };
  }

  Set<Marker> _buildPlaceMarkers(
    List<NearbyPlace> places, {
    NearbyPlace? topRecommendedPlace,
  }) {
    return places
        .where((NearbyPlace place) {
          return place.latitude != null && place.longitude != null;
        })
        .map((NearbyPlace place) {
          return Marker(
            markerId: MarkerId(place.id ?? _markerId(place)),
            position: LatLng(place.latitude!, place.longitude!),
            icon: _markerIconForPlace(
              place,
              topRecommendedPlace: topRecommendedPlace,
            ),
            infoWindow: InfoWindow(
              title: place.name,
              snippet: _displayType(place),
            ),
            onTap: () => _openPlaceSheet(place),
          );
        })
        .toSet();
  }

  Set<Marker> _buildEventMarkers(List<EventItem> events) {
    return events.map((EventItem event) {
      return Marker(
        markerId: MarkerId(_eventMarkerId(event)),
        position: LatLng(event.latitude, event.longitude),
        icon: _markerIconForEvent(),
        infoWindow: InfoWindow(title: event.title, snippet: event.category),
        onTap: () => _openEventSheet(event),
      );
    }).toSet();
  }

  BitmapDescriptor _markerIconForPlace(
    NearbyPlace place, {
    NearbyPlace? topRecommendedPlace,
  }) {
    if (_isTopRecommendedPlace(place, topRecommendedPlace)) {
      return _markerIconCache[_topRecommendationMarkerCacheKey] ??
          _fallbackTopRecommendationMarkerIcon;
    }

    final markerCacheKey = _placeMarkerCacheKey(place);
    final cachedMarker = _markerIconCache[markerCacheKey];
    if (cachedMarker != null) {
      return cachedMarker;
    }

    if (place.isUserPlace) {
      return _fallbackUserPlaceMarkerIcon;
    }

    if (_isRecommendedPlace(place)) {
      return _fallbackRecommendedPlaceMarkerIcon;
    }

    return _fallbackDefaultPlaceMarkerIcon;
  }

  bool _isTopRecommendedPlace(
    NearbyPlace place,
    NearbyPlace? topRecommendedPlace,
  ) {
    if (topRecommendedPlace == null) {
      return false;
    }

    final placeId = place.id ?? _markerId(place);
    final topPlaceId = topRecommendedPlace.id ?? _markerId(topRecommendedPlace);
    return placeId == topPlaceId;
  }

  BitmapDescriptor _markerIconForEvent() {
    return _markerIconCache[_eventMarkerCacheKey] ?? _fallbackEventMarkerIcon;
  }

  static const String _eventMarkerCacheKey = 'event';
  static const String _topRecommendationMarkerCacheKey = 'top-recommendation';

  String _placeMarkerCacheKey(NearbyPlace place) {
    final markerKind = _markerKindForPlace(place);
    final glyph = _markerGlyphForPlace(place);
    return '${markerKind.name}-${glyph.codePoint}';
  }

  ExploreMarkerKind _markerKindForPlace(NearbyPlace place) {
    if (place.isUserPlace) {
      return ExploreMarkerKind.userPlace;
    }

    if (_isRecommendedPlace(place)) {
      return ExploreMarkerKind.recommendedPlace;
    }

    return ExploreMarkerKind.defaultPlace;
  }

  IconData _markerGlyphForPlace(NearbyPlace place) {
    if (place.types.contains('cinema')) {
      return Icons.local_movies_rounded;
    }
    if (place.types.contains('librairie')) {
      return Icons.menu_book_rounded;
    }
    if (place.types.contains('bord de mer')) {
      return Icons.waves_rounded;
    }
    if (place.types.contains('parc') || place.types.contains('nature')) {
      return Icons.park_rounded;
    }
    if (place.types.contains('musee')) {
      return Icons.museum_rounded;
    }
    if (place.types.contains('atelier') || place.types.contains('expo')) {
      return Icons.palette_rounded;
    }
    if (place.types.contains('bar') || place.types.contains('evenement')) {
      return Icons.groups_rounded;
    }

    return Icons.local_cafe_rounded;
  }

  Future<void> _preloadMarkerIcons() async {
    await Future.wait<void>(<Future<void>>[
      _ensureEventMarkerIcon(),
      _ensureTopRecommendationMarkerIcon(),
    ]);
  }

  Future<void> _prepareMarkerIcons({
    required List<NearbyPlace> places,
    required List<EventItem> events,
  }) async {
    final futures = <Future<void>>[
      if (events.isNotEmpty) _ensureEventMarkerIcon(),
      _ensureTopRecommendationMarkerIcon(),
      ...places
          .where((NearbyPlace place) {
            return place.latitude != null && place.longitude != null;
          })
          .map(_ensurePlaceMarkerIcon),
    ];

    if (futures.isEmpty) {
      return;
    }

    await Future.wait<void>(futures);
  }

  Future<void> _ensurePlaceMarkerIcon(NearbyPlace place) async {
    final markerCacheKey = _placeMarkerCacheKey(place);
    if (_markerIconCache.containsKey(markerCacheKey)) {
      return;
    }

    await _createAndStoreMarkerIcon(
      cacheKey: markerCacheKey,
      kind: _markerKindForPlace(place),
      glyph: _markerGlyphForPlace(place),
    );
  }

  Future<void> _ensureTopRecommendationMarkerIcon() async {
    if (_markerIconCache.containsKey(_topRecommendationMarkerCacheKey)) {
      return;
    }

    await _createAndStoreMarkerIcon(
      cacheKey: _topRecommendationMarkerCacheKey,
      kind: ExploreMarkerKind.topRecommendation,
      glyph: Icons.auto_awesome_rounded,
    );
  }

  Future<void> _ensureEventMarkerIcon() async {
    if (_markerIconCache.containsKey(_eventMarkerCacheKey)) {
      return;
    }

    await _createAndStoreMarkerIcon(
      cacheKey: _eventMarkerCacheKey,
      kind: ExploreMarkerKind.event,
      glyph: Icons.event_rounded,
    );
  }

  Future<void> _createAndStoreMarkerIcon({
    required String cacheKey,
    required ExploreMarkerKind kind,
    required IconData glyph,
  }) async {
    try {
      final devicePixelRatio = MediaQuery.maybeDevicePixelRatioOf(context) ?? 1;
      final markerIcon = await ExploreMarkerFactory.createMarker(
        devicePixelRatio: devicePixelRatio,
        glyph: glyph,
        kind: kind,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _markerIconCache[cacheKey] = markerIcon;
      });
    } catch (error, stackTrace) {
      debugPrint(
        'ExplorePage: failed to generate custom marker icon for key=$cacheKey.',
      );
      debugPrint('$error');
      debugPrint('$stackTrace');
    }
  }

  bool _isRecommendedPlace(NearbyPlace place) {
    return place.recommendationScore >= 4;
  }

  List<NearbyPlace> _visiblePlaces(List<NearbyPlace> places) {
    switch (_activeFilter) {
      case ExploreFilterType.all:
        return places;
      case ExploreFilterType.forMe:
        return places.where(_isRecommendedPlace).toList();
      case ExploreFilterType.myPlaces:
        return places.where((NearbyPlace place) => place.isUserPlace).toList();
      case ExploreFilterType.events:
        return const <NearbyPlace>[];
    }
  }

  List<EventItem> _visibleEvents(List<EventItem> events) {
    switch (_activeFilter) {
      case ExploreFilterType.all:
      case ExploreFilterType.events:
        return events;
      case ExploreFilterType.forMe:
      case ExploreFilterType.myPlaces:
        return const <EventItem>[];
    }
  }

  Future<void> _handleFilterChanged(ExploreFilterType filter) async {
    if (_activeFilter == filter) {
      return;
    }

    setState(() {
      _activeFilter = filter;
    });

    final result = _result;
    if (result == null || !_supportsInteractiveMap) {
      return;
    }

    await _updateMapViewport(
      places: _visiblePlaces(result.places),
      events: _visibleEvents(result.events),
      fallbackLocation: result.centerLocation,
    );
  }

  Future<void> _updateMapViewport({
    required List<NearbyPlace> places,
    required List<EventItem> events,
    required AppLocation fallbackLocation,
  }) async {
    if (!_mapControllerCompleter.isCompleted) {
      return;
    }

    final positions = <LatLng>[
      ...places
          .where((NearbyPlace place) {
            return place.latitude != null && place.longitude != null;
          })
          .map(
            (NearbyPlace place) => LatLng(place.latitude!, place.longitude!),
          ),
      ...events.map(
        (EventItem event) => LatLng(event.latitude, event.longitude),
      ),
    ];

    if (positions.isEmpty) {
      await _animateCameraTo(fallbackLocation);
      return;
    }

    final controller = await _mapControllerCompleter.future;
    final bounds = _buildBounds(positions);

    try {
      if (bounds == null) {
        await controller.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: positions.first, zoom: 14.2),
          ),
        );
        return;
      }

      await controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 72));
    } catch (_) {
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: positions.first, zoom: 13.7),
        ),
      );
    }
  }

  LatLngBounds? _buildBounds(List<LatLng> positions) {
    if (positions.isEmpty) {
      return null;
    }

    var minLat = positions.first.latitude;
    var maxLat = positions.first.latitude;
    var minLng = positions.first.longitude;
    var maxLng = positions.first.longitude;

    for (final position in positions.skip(1)) {
      if (position.latitude < minLat) {
        minLat = position.latitude;
      }
      if (position.latitude > maxLat) {
        maxLat = position.latitude;
      }
      if (position.longitude < minLng) {
        minLng = position.longitude;
      }
      if (position.longitude > maxLng) {
        maxLng = position.longitude;
      }
    }

    if (minLat == maxLat && minLng == maxLng) {
      return null;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  String _markerId(NearbyPlace place) {
    return '${place.name}-${place.latitude}-${place.longitude}';
  }

  String _eventMarkerId(EventItem event) {
    return 'event-${event.title}-${event.latitude}-${event.longitude}';
  }

  String _displayType(NearbyPlace place) {
    for (final type in PlaceMetadata.selectableTypes) {
      if (place.types.contains(type)) {
        return PlaceMetadata.labelForType(type);
      }
    }

    return place.category;
  }

  String _displayEventType(EventItem event) {
    return event.category;
  }

  Future<void> _openDirectionsForPlace(NearbyPlace place) async {
    final latitude = place.latitude;
    final longitude = place.longitude;
    if (latitude == null || longitude == null) {
      debugPrint(
        'ExplorePage: selected place "${place.name}" has no coordinates. '
        'Google Maps launch skipped.',
      );
      return;
    }

    debugPrint(
      'ExplorePage: selected place "${place.name}". '
      'Opening Google Maps with coordinates $latitude,$longitude.',
    );

    final launched = await GoogleMapsLauncher.openPlace(
      latitude: latitude,
      longitude: longitude,
    );
    if (launched || !mounted) {
      return;
    }

    debugPrint(
      'ExplorePage: Google Maps launch failed for "${place.name}" '
      'with coordinates $latitude,$longitude.',
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Impossible d ouvrir l itineraire pour ce lieu.'),
      ),
    );
  }

  Future<void> _openMapLocationForEvent(EventItem event) async {
    debugPrint(
      'ExplorePage: selected event "${event.title}". '
      'Opening Google Maps with coordinates ${event.latitude},${event.longitude}.',
    );

    final launched = await GoogleMapsLauncher.openPlace(
      latitude: event.latitude,
      longitude: event.longitude,
    );
    if (launched || !mounted) {
      return;
    }

    debugPrint(
      'ExplorePage: Google Maps launch failed for event "${event.title}" '
      'with coordinates ${event.latitude},${event.longitude}.',
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Impossible d ouvrir ce lieu dans Google Maps.'),
      ),
    );
  }

  Future<void> _openPlaceSheet(NearbyPlace place) async {
    debugPrint(
      'ExplorePage: place sheet opened for "${place.name}" '
      'at ${place.latitude},${place.longitude}.',
    );

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (BuildContext context) {
        final theme = Theme.of(context);

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          place.name,
                          style: theme.textTheme.titleLarge,
                        ),
                      ),
                      if (place.isUserPlace)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceSoft,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(
                            'Ton lieu',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _PlaceSheetRow(label: 'Type', value: _displayType(place)),
                  _PlaceSheetRow(label: 'Distance', value: place.distance),
                  if (place.recommendationReason != null) ...<Widget>[
                    const SizedBox(height: 6),
                    _RecommendationCallout(
                      message: place.recommendationReason!,
                    ),
                  ],
                  _PlaceSheetRow(
                    label: 'Coordonnees',
                    value:
                        '${place.latitude?.toStringAsFixed(4)}, ${place.longitude?.toStringAsFixed(4)}',
                  ),
                  if (place.latitude != null &&
                      place.longitude != null) ...<Widget>[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => _openDirectionsForPlace(place),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          backgroundColor: AppColors.primaryOrange,
                          foregroundColor: AppColors.softBlack,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: const Icon(Icons.directions_rounded),
                        label: const Text('Itineraire'),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    'Enrichir ce moment',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 10),
                  PlaceJournalActions(
                    onFavoritePressed: () => _savePlaceSelection(
                      place: place,
                      status: CheckinPlaceStatus.favorite,
                    ),
                    onLaterPressed: () => _savePlaceSelection(
                      place: place,
                      status: CheckinPlaceStatus.later,
                    ),
                    onVisitedPressed: () => _savePlaceSelection(
                      place: place,
                      status: CheckinPlaceStatus.visited,
                    ),
                    onNotePressed: () => _promptForPlaceNote(place),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _openEventSheet(EventItem event) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (BuildContext context) {
        final theme = Theme.of(context);

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(event.title, style: theme.textTheme.titleLarge),
                  const SizedBox(height: 10),
                  _PlaceSheetRow(
                    label: 'Type',
                    value: _displayEventType(event),
                  ),
                  _PlaceSheetRow(label: 'Lieu', value: event.locationName),
                  _PlaceSheetRow(
                    label: 'Horaire',
                    value: _formatEventDateTime(event.dateTime),
                  ),
                  if (event.recommendationReason != null) ...<Widget>[
                    const SizedBox(height: 6),
                    _RecommendationCallout(
                      message: event.recommendationReason!,
                    ),
                  ],
                  _PlaceSheetRow(
                    label: 'Coordonnees',
                    value:
                        '${event.latitude.toStringAsFixed(4)}, ${event.longitude.toStringAsFixed(4)}',
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => _openMapLocationForEvent(event),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        backgroundColor: AppColors.primaryOrange,
                        foregroundColor: AppColors.softBlack,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.place_rounded),
                      label: const Text('Voir le lieu'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _buildRecommendationKey(CheckinRecord? record) {
    return <String>[
      record?.currentEmotion ?? '',
      record?.desiredEmotion ?? '',
      record?.activity ?? '',
    ].join('|');
  }

  String _formatEventDateTime(DateTime dateTime) {
    final weekday =
        _weekdayLabels[(dateTime.weekday - 1) % _weekdayLabels.length];
    final month = _monthLabels[(dateTime.month - 1) % _monthLabels.length];
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$weekday ${dateTime.day} $month, $hour:$minute';
  }

  String? _buildStatusMessage(ExplorePlacesResult? result) {
    if (_mapState == _ExploreMapState.error) {
      return 'La carte n a pas pu s initialiser. Un fallback propre est affiche.';
    }

    if (kIsWeb && !_webMapsRuntime.isScriptAvailable) {
      switch (_webMapsRuntime.unavailableReason) {
        case 'google_maps_web_config_missing':
          return 'Config Google Maps Web absente. Ajoute web/google_maps_config.js pour afficher la carte.';
        case 'google_maps_api_key_missing_in_web_config':
          return 'Cle Google Maps Web absente dans la config locale. Un fallback est affiche.';
        case 'google_maps_script_load_failed':
          return 'Le script Google Maps Web n a pas pu se charger. Un fallback est affiche.';
        default:
          return 'Google Maps Web non disponible. Un fallback propre est affiche a la place de la carte.';
      }
    }

    if (result == null) {
      return null;
    }

    switch (result.locationStatus) {
      case AppLocationStatus.available:
        if (result.usedFallbackPlaces) {
          return 'Position detectee. Les lieux fallback restent affiches si les sources distantes sont vides.';
        }
        return null;
      case AppLocationStatus.servicesDisabled:
        return 'Localisation desactivee. Carte centree sur une position par defaut.';
      case AppLocationStatus.permissionDenied:
        return 'Permission de localisation refusee. Carte centree sur une position par defaut.';
      case AppLocationStatus.permissionDeniedForever:
        return 'Permission de localisation desactivee durablement. Carte centree sur une position par defaut.';
      case AppLocationStatus.unavailable:
        if (_isRecoveringUserLocation) {
          return null;
        }
        return 'Position indisponible pour le moment. Carte centree sur une position par defaut.';
    }
  }

  @override
  Widget build(BuildContext context) {
    _logWebMapsStateIfNeeded();

    final theme = Theme.of(context);
    final result = _result;
    final allPlaces = result?.places ?? const <NearbyPlace>[];
    final topRecommendedPlace = RecommendationService.instance
        .topRecommendedPlace(places: allPlaces);
    final places = _visiblePlaces(allPlaces);
    final events = _visibleEvents(result?.events ?? const <EventItem>[]);
    final markers = _buildMarkers(
      places: places,
      events: events,
      topRecommendedPlace: topRecommendedPlace,
    );
    final cameraTarget = result == null
        ? _defaultLatLng
        : LatLng(
            result.centerLocation.latitude,
            result.centerLocation.longitude,
          );
    final statusMessage = _buildStatusMessage(result);

    return SafeArea(
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: _showsInteractiveMap
                ? GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: cameraTarget,
                      zoom: 13.7,
                    ),
                    style: _exploreMapStyle,
                    onMapCreated: (GoogleMapController controller) {
                      if (!_mapControllerCompleter.isCompleted) {
                        _mapControllerCompleter.complete(controller);
                      }
                      _mapInitTimeoutTimer?.cancel();
                      _setMapState(
                        _ExploreMapState.ready,
                        source: 'on_map_created',
                      );
                    },
                    markers: markers,
                    myLocationEnabled: result?.hasUserLocation ?? false,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    mapToolbarEnabled: false,
                    compassEnabled: false,
                  )
                : _UnsupportedMapFallback(markerCount: markers.length),
          ),
          Positioned(
            top: 24,
            left: 24,
            right: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.78),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    'Explorer',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppColors.ink,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.78),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.border),
                    boxShadow: const <BoxShadow>[
                      BoxShadow(
                        color: AppColors.shadow,
                        blurRadius: 24,
                        offset: Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Lieux recommandes autour de toi',
                        style: theme.textTheme.displaySmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Retrouve sur la carte les lieux deja proposes dans Honvie.',
                        style: theme.textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: ExploreFilterType.values.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (BuildContext context, int index) {
                      final filter = ExploreFilterType.values[index];
                      final isSelected = filter == _activeFilter;

                      return FilterChip(
                        label: Text(filter.label),
                        selected: isSelected,
                        onSelected: (_) => _handleFilterChanged(filter),
                        showCheckmark: false,
                        labelStyle: theme.textTheme.bodyMedium?.copyWith(
                          color: isSelected ? AppColors.white : AppColors.ink,
                          fontWeight: FontWeight.w600,
                        ),
                        backgroundColor: AppColors.white.withValues(
                          alpha: 0.84,
                        ),
                        selectedColor: AppColors.ink,
                        side: BorderSide(
                          color: isSelected ? AppColors.ink : AppColors.border,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                      );
                    },
                  ),
                ),
                if (statusMessage != null) ...<Widget>[
                  const SizedBox(height: 12),
                  _InfoBanner(message: statusMessage),
                ],
              ],
            ),
          ),
          if (!_isLoading && places.isEmpty && events.isEmpty)
            const Positioned.fill(child: _EmptyMapOverlay()),
          if (_isLoading)
            Container(
              color: AppColors.white.withValues(alpha: 0.48),
              alignment: Alignment.center,
              child: const CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }

  void _logWebMapsStateIfNeeded() {
    if (!kIsWeb || _didLogWebMapsState) {
      return;
    }

    _didLogWebMapsState = true;

    if (_webMapsRuntime.isScriptAvailable) {
      debugPrint('ExplorePage: Google Maps web script detected successfully.');
      return;
    }

    debugPrint(
      'ExplorePage: Google Maps web script unavailable. '
      'reason=${_webMapsRuntime.unavailableReason ?? 'unknown'}.',
    );
  }

  void _syncMapState({required String source}) {
    if (!_supportsInteractiveMap) {
      _mapInitTimeoutTimer?.cancel();
      _setMapState(
        _ExploreMapState.fallback,
        reason: _resolveMapUnavailableReason(),
        source: source,
      );
      return;
    }

    if (_mapControllerCompleter.isCompleted) {
      _mapInitTimeoutTimer?.cancel();
      _setMapState(_ExploreMapState.ready, source: source);
      return;
    }

    _armMapInitTimeout();
    _setMapState(
      _ExploreMapState.loading,
      reason: 'awaiting_google_map_controller',
      source: source,
    );
  }

  void _armMapInitTimeout() {
    if (_mapControllerCompleter.isCompleted ||
        _mapInitTimeoutTimer?.isActive == true) {
      return;
    }

    _mapInitTimeoutTimer = Timer(const Duration(seconds: 8), () {
      if (!mounted || _mapControllerCompleter.isCompleted) {
        return;
      }

      _setMapState(
        _ExploreMapState.error,
        reason: 'map_controller_timeout',
        source: 'map_init_timeout',
      );
    });
  }

  String _resolveMapUnavailableReason() {
    if (kIsWeb) {
      return _webMapsRuntime.unavailableReason ??
          'google_maps_script_unavailable';
    }

    return 'interactive_map_not_supported_on_this_platform';
  }

  void _setMapState(
    _ExploreMapState nextState, {
    String? reason,
    required String source,
  }) {
    if (_mapState == nextState && _mapStateReason == reason) {
      return;
    }

    switch (nextState) {
      case _ExploreMapState.loading:
        debugPrint(
          'ExplorePage: map loading started. source=$source, reason=${reason ?? 'none'}.',
        );
        break;
      case _ExploreMapState.ready:
        debugPrint('ExplorePage: map loaded successfully.');
        break;
      case _ExploreMapState.fallback:
        debugPrint(
          'ExplorePage: map fallback used. source=$source, reason=${reason ?? 'unknown'}.',
        );
        break;
      case _ExploreMapState.error:
        debugPrint(
          'ExplorePage: map init failed with reason=${reason ?? 'unknown'}. '
          'Fallback will be displayed.',
        );
        break;
    }

    if (!mounted) {
      _mapState = nextState;
      _mapStateReason = reason;
      return;
    }

    setState(() {
      _mapState = nextState;
      _mapStateReason = reason;
    });
  }

  static const List<String> _weekdayLabels = <String>[
    'Lun',
    'Mar',
    'Mer',
    'Jeu',
    'Ven',
    'Sam',
    'Dim',
  ];

  static const List<String> _monthLabels = <String>[
    'jan',
    'fev',
    'mar',
    'avr',
    'mai',
    'jun',
    'jul',
    'aou',
    'sep',
    'oct',
    'nov',
    'dec',
  ];
}

extension on _ExplorePageState {
  Future<void> _savePlaceSelection({
    required NearbyPlace place,
    CheckinPlaceStatus? status,
    String? note,
  }) async {
    final todayRecord = _store.todayRecord;
    if (todayRecord == null) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Valide d abord ton check-in du jour pour enrichir ce moment.',
          ),
        ),
      );
      return;
    }

    try {
      final updatedRecord = await _checkinService.updateTodayJournalContext(
        selectedPlaceName: place.name,
        selectedPlaceStatus: status,
        writtenNote: note,
      );
      _store.applyPersistedRecord(updatedRecord);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_placeActionMessage(place, status, note))),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible d enregistrer ce moment pour le moment.'),
        ),
      );
    }
  }

  Future<void> _promptForPlaceNote(NearbyPlace place) async {
    final note = await showPlaceNoteDialog(
      context,
      title: 'Ajouter une note pour ce lieu',
    );
    if (note == null || note.trim().isEmpty) {
      return;
    }

    await _savePlaceSelection(place: place, note: note);
  }

  String _placeActionMessage(
    NearbyPlace place,
    CheckinPlaceStatus? status,
    String? note,
  ) {
    if (note != null && note.trim().isNotEmpty) {
      return 'Ta note a ete ajoutee a ${place.name}.';
    }

    switch (status) {
      case CheckinPlaceStatus.favorite:
        return '${place.name} a ete ajoute en favori.';
      case CheckinPlaceStatus.later:
        return '${place.name} est garde pour plus tard.';
      case CheckinPlaceStatus.visited:
        return '${place.name} est marque comme visite.';
      case null:
        return 'Ton moment a ete mis a jour.';
    }
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.ink,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _RecommendationCallout extends StatelessWidget {
  const _RecommendationCallout({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.ink,
          fontWeight: FontWeight.w600,
          height: 1.3,
        ),
      ),
    );
  }
}

class _UnsupportedMapFallback extends StatelessWidget {
  const _UnsupportedMapFallback({required this.markerCount});

  final int markerCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            AppColors.surfaceSoft,
            AppColors.white.withValues(alpha: 0.96),
          ],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.map_rounded, size: 42, color: AppColors.ink),
              const SizedBox(height: 12),
              Text(
                'Carte interactive indisponible sur cette plateforme.',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                '$markerCount point(s) charges pour Explorer.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyMapOverlay extends StatelessWidget {
  const _EmptyMapOverlay();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          'Aucun lieu ou evenement a afficher pour le moment.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}

class _PlaceSheetRow extends StatelessWidget {
  const _PlaceSheetRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.mutedInk,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.ink),
            ),
          ),
        ],
      ),
    );
  }
}
