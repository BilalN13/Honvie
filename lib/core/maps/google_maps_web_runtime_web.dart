// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:js_interop';
import 'dart:js_util' as js_util;

import 'google_maps_web_runtime.dart';

@JS()
external JSObject get globalThis;

class _WebGoogleMapsWebRuntime implements GoogleMapsWebRuntime {
  @override
  bool get isScriptAvailable {
    if (_hasGoogleMapsNamespace) {
      return true;
    }

    return _loadedFlag == true;
  }

  @override
  String? get unavailableReason {
    final error = _errorFlag;
    if (error != null && error.isNotEmpty) {
      return error;
    }

    if (_hasGoogleNamespace && !_hasGoogleMapsNamespace) {
      return 'google_namespace_without_maps';
    }

    return 'google_maps_script_unavailable';
  }

  bool get _hasGoogleNamespace => js_util.hasProperty(globalThis, 'google');

  bool get _hasGoogleMapsNamespace {
    if (!_hasGoogleNamespace) {
      return false;
    }

    final Object? google = js_util.getProperty<Object?>(globalThis, 'google');
    return google != null && js_util.hasProperty(google, 'maps');
  }

  bool? get _loadedFlag {
    if (!js_util.hasProperty(globalThis, '__honvieGoogleMapsLoaded')) {
      return null;
    }

    final Object? value = js_util.getProperty<Object?>(
      globalThis,
      '__honvieGoogleMapsLoaded',
    );
    return value == true;
  }

  String? get _errorFlag {
    if (!js_util.hasProperty(globalThis, '__honvieGoogleMapsError')) {
      return null;
    }

    final Object? value = js_util.getProperty<Object?>(
      globalThis,
      '__honvieGoogleMapsError',
    );
    return value?.toString();
  }
}

GoogleMapsWebRuntime createRuntime() => _WebGoogleMapsWebRuntime();
