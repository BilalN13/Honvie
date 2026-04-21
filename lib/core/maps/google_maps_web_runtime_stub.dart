import 'google_maps_web_runtime.dart';

class _StubGoogleMapsWebRuntime implements GoogleMapsWebRuntime {
  @override
  bool get isScriptAvailable => true;

  @override
  String? get unavailableReason => null;
}

GoogleMapsWebRuntime createRuntime() => _StubGoogleMapsWebRuntime();
