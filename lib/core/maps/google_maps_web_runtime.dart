import 'google_maps_web_runtime_stub.dart'
    if (dart.library.js) 'google_maps_web_runtime_web.dart';

abstract class GoogleMapsWebRuntime {
  bool get isScriptAvailable;
  String? get unavailableReason;
}

GoogleMapsWebRuntime createGoogleMapsWebRuntime() => createRuntime();
