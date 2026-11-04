import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class SecurityNativeService {
  static const MethodChannel _channel =
      MethodChannel('com.example.gym_managment_app/security');

  /// Set to true during security unit tests that mock the platform channel
  static bool enableInTests = false;

  static Future<void> setSecureMode(bool enabled) async {
    if (kIsWeb) return;
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      if (!enableInTests) return;
      try {
        await _channel.invokeMethod('setSecureMode', {'enabled': enabled});
      } catch (_) {}
      return;
    }
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('setSecureMode', {'enabled': enabled});
    } catch (_) {
      // Ignored on non-supported environments
    }
  }
}
