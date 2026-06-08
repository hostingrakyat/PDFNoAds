import 'package:flutter/services.dart';

/// Thin wrapper around the native `com.pdfnoads.app/intent` MethodChannel.
class IntentService {
  IntentService._();

  static const _channel = MethodChannel('com.pdfnoads.app/intent');

  /// The URI the app was launched with (file:// or content://), or null.
  /// Consumes the pending value: a second call returns null.
  static Future<String?> getInitialUri() async {
    try {
      return await _channel.invokeMethod<String>('getInitialUri');
    } catch (_) {
      return null;
    }
  }

  /// Human-readable file name for a content:// URI (falls back to last segment).
  static Future<String?> getDisplayName(String uri) async {
    try {
      return await _channel.invokeMethod<String>('getDisplayName', {'uri': uri});
    } catch (_) {
      return null;
    }
  }

  /// Reads the bytes of a content:// (or file://) URI.
  static Future<Uint8List?> readUri(String uri) {
    return _channel.invokeMethod<Uint8List>('readUri', {'uri': uri});
  }

  /// Shares a local file through the Android share sheet.
  static Future<void> shareFile(String path, {String? name}) {
    return _channel.invokeMethod('shareFile', {'path': path, 'name': name});
  }

  /// Opens the system "default apps" settings.
  static Future<void> openDefaultApps() {
    return _channel.invokeMethod('openDefaultApps').catchError((_) {});
  }
}
