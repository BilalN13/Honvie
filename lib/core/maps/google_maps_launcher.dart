import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

abstract final class GoogleMapsLauncher {
  static Uri directionsUri({
    required double latitude,
    required double longitude,
  }) {
    return Uri.https('www.google.com', '/maps/dir/', <String, String>{
      'api': '1',
      'destination': '$latitude,$longitude',
    });
  }

  static Uri placeUri({required double latitude, required double longitude}) {
    return Uri.https('www.google.com', '/maps/search/', <String, String>{
      'api': '1',
      'query': '$latitude,$longitude',
    });
  }

  static Future<bool> openDirections({
    required double latitude,
    required double longitude,
  }) async {
    final uri = directionsUri(latitude: latitude, longitude: longitude);
    debugPrint(
      'GoogleMapsLauncher: launching directions with destination=$latitude,$longitude.',
    );

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (launched) {
        debugPrint(
          'GoogleMapsLauncher: directions launch succeeded for $latitude,$longitude.',
        );
      }
      if (!launched) {
        debugPrint('GoogleMapsLauncher: failed to launch directions uri=$uri.');
      }
      return launched;
    } catch (error, stackTrace) {
      debugPrint('GoogleMapsLauncher: directions launch threw an exception.');
      debugPrint('$error');
      debugPrint('$stackTrace');
      return false;
    }
  }

  static Future<bool> openPlace({
    required double latitude,
    required double longitude,
  }) async {
    final uri = placeUri(latitude: latitude, longitude: longitude);
    debugPrint(
      'GoogleMapsLauncher: launching place search with query=$latitude,$longitude.',
    );

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (launched) {
        debugPrint(
          'GoogleMapsLauncher: place launch succeeded for $latitude,$longitude.',
        );
      }
      if (!launched) {
        debugPrint('GoogleMapsLauncher: failed to launch place uri=$uri.');
      }
      return launched;
    } catch (error, stackTrace) {
      debugPrint('GoogleMapsLauncher: place launch threw an exception.');
      debugPrint('$error');
      debugPrint('$stackTrace');
      return false;
    }
  }
}
