import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class AppLocation {
  const AppLocation({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;
}

enum AppLocationStatus {
  available,
  servicesDisabled,
  permissionDenied,
  permissionDeniedForever,
  unavailable,
}

class AppLocationResult {
  const AppLocationResult({required this.status, this.location});

  final AppLocationStatus status;
  final AppLocation? location;
}

class LocationService {
  LocationService._();

  static final LocationService instance = LocationService._();

  Future<AppLocationResult> resolveCurrentLocation({
    Duration? overallTimeout,
    Duration? positionTimeLimit,
  }) async {
    debugPrint(
      'LocationService: resolveCurrentLocation started. '
      'platform=${kIsWeb ? 'web' : defaultTargetPlatform.name}, '
      'overallTimeout=${_formatDuration(overallTimeout)}, '
      'positionTimeLimit=${_formatDuration(positionTimeLimit)}.',
    );

    final resolveFuture = _resolveCurrentLocationInternal(
      positionTimeLimit: positionTimeLimit,
    );

    if (overallTimeout == null) {
      return resolveFuture;
    }

    try {
      return await resolveFuture.timeout(overallTimeout);
    } on TimeoutException catch (error, stackTrace) {
      debugPrint(
        'LocationService: overall location resolution timed out after '
        '${_formatDuration(overallTimeout)}.',
      );
      debugPrint('$error');
      debugPrint('$stackTrace');
      return const AppLocationResult(status: AppLocationStatus.unavailable);
    }
  }

  Future<AppLocationResult> _resolveCurrentLocationInternal({
    Duration? positionTimeLimit,
  }) async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      debugPrint('LocationService: serviceEnabled=$serviceEnabled.');
      if (!serviceEnabled) {
        debugPrint('LocationService: location services are disabled.');
        return const AppLocationResult(
          status: AppLocationStatus.servicesDisabled,
        );
      }

      var permission = await Geolocator.checkPermission();
      debugPrint(
        'LocationService: permission status before request=$permission.',
      );
      if (permission == LocationPermission.denied) {
        if (kIsWeb) {
          debugPrint(
            'LocationService: web permission request will be triggered by '
            'getCurrentPosition to preserve the browser result.',
          );
        } else {
          debugPrint('LocationService: requesting location permission.');
          permission = await Geolocator.requestPermission();
          debugPrint(
            'LocationService: permission status after request=$permission.',
          );
        }
      }

      if (permission == LocationPermission.denied) {
        if (kIsWeb) {
          debugPrint(
            'LocationService: web permission is still pending browser prompt. '
            'Proceeding with getCurrentPosition.',
          );
        } else {
          debugPrint('LocationService: location permission denied.');
          return const AppLocationResult(
            status: AppLocationStatus.permissionDenied,
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('LocationService: location permission denied forever.');
        return const AppLocationResult(
          status: AppLocationStatus.permissionDeniedForever,
        );
      }

      if (permission == LocationPermission.unableToDetermine) {
        debugPrint(
          'LocationService: permission status unableToDetermine. '
          'Attempting getCurrentPosition anyway.',
        );
      }

      final locationSettings = LocationSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: positionTimeLimit,
      );
      debugPrint(
        'LocationService: calling getCurrentPosition with '
        'accuracy=${locationSettings.accuracy}, '
        'timeLimit=${_formatDuration(positionTimeLimit)}.',
      );
      final position = await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      );

      debugPrint(
        'LocationService: position retrieved lat=${position.latitude}, lng=${position.longitude}.',
      );

      final location = AppLocation(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      return AppLocationResult(
        status: AppLocationStatus.available,
        location: location,
      );
    } on PermissionDeniedException catch (error, stackTrace) {
      debugPrint(
        'LocationService: getCurrentPosition failed because permission was denied.',
      );
      debugPrint('$error');
      debugPrint('$stackTrace');
      return const AppLocationResult(
        status: AppLocationStatus.permissionDenied,
      );
    } on LocationServiceDisabledException catch (error, stackTrace) {
      debugPrint(
        'LocationService: getCurrentPosition failed because location services are disabled.',
      );
      debugPrint('$error');
      debugPrint('$stackTrace');
      return const AppLocationResult(
        status: AppLocationStatus.servicesDisabled,
      );
    } on TimeoutException catch (error, stackTrace) {
      debugPrint(
        'LocationService: getCurrentPosition timed out before a location was received.',
      );
      debugPrint('$error');
      debugPrint('$stackTrace');
      return const AppLocationResult(status: AppLocationStatus.unavailable);
    } catch (error, stackTrace) {
      debugPrint(
        'LocationService: failed to retrieve location. '
        'errorType=${error.runtimeType}.',
      );
      debugPrint('$error');
      debugPrint('$stackTrace');
      return const AppLocationResult(status: AppLocationStatus.unavailable);
    }
  }

  Future<AppLocation?> getCurrentLocation({
    Duration? overallTimeout,
    Duration? positionTimeLimit,
  }) async {
    final result = await resolveCurrentLocation(
      overallTimeout: overallTimeout,
      positionTimeLimit: positionTimeLimit,
    );
    if (result.location == null) {
      debugPrint(
        'LocationService: getCurrentLocation returned null. '
        'status=${result.status}.',
      );
    }
    return result.location;
  }

  static String _formatDuration(Duration? duration) {
    if (duration == null) {
      return 'none';
    }

    return '${duration.inMilliseconds}ms';
  }
}
