import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../repositories/security_repository_impl.dart';

abstract class SecurityLocalDataSource {
  Future<String> getPin();
  Future<void> savePin(String pin);
  Future<bool> isSecurityEnabled();
  Future<void> setSecurityEnabled(bool enabled);
  Future<void> resetPinToDefault();
}

class SecurityLocalDataSourceImpl implements SecurityLocalDataSource {
  final FlutterSecureStorage secureStorage;

  static const String pinKey = 'app_security_pin';
  static const String enabledKey = 'app_security_enabled';
  static const String defaultPin = '0000';

  SecurityLocalDataSourceImpl({required this.secureStorage});

  @override
  Future<String> getPin() async {
    final pin = await secureStorage.read(key: pinKey);
    if (pin == null || pin.isEmpty) {
      final defaultHashed = SecurityRepositoryImpl.hashPin(defaultPin);
      await secureStorage.write(key: pinKey, value: defaultHashed);
      return defaultHashed;
    }
    return pin;
  }

  @override
  Future<void> savePin(String pin) async {
    await secureStorage.write(key: pinKey, value: pin);
  }

  @override
  Future<bool> isSecurityEnabled() async {
    final enabled = await secureStorage.read(key: enabledKey);
    if (enabled == null) {
      await secureStorage.write(key: enabledKey, value: 'true');
      return true;
    }
    return enabled == 'true';
  }

  @override
  Future<void> setSecurityEnabled(bool enabled) async {
    await secureStorage.write(key: enabledKey, value: enabled.toString());
  }

  @override
  Future<void> resetPinToDefault() async {
    final defaultHashed = SecurityRepositoryImpl.hashPin(defaultPin);
    await secureStorage.write(key: pinKey, value: defaultHashed);
  }
}
