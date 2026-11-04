import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../../domain/repositories/security_repository.dart';
import '../datasources/security_local_datasource.dart';

class SecurityRepositoryImpl implements SecurityRepository {
  final SecurityLocalDataSource localDataSource;

  static const String _pinSalt = 'gym_secure_salt_';

  static String hashPin(String pin) {
    final bytes = utf8.encode('$_pinSalt$pin');
    return sha256.convert(bytes).toString();
  }

  SecurityRepositoryImpl({required this.localDataSource});

  @override
  Future<String> getPin() => localDataSource.getPin();

  @override
  Future<bool> verifyPin(String pin) async {
    final current = await localDataSource.getPin();
    if (current == pin) {
      // Transparently migrate unhashed legacy PIN to SHA-256 hash
      await setPin(pin);
      return true;
    }
    return current == hashPin(pin);
  }

  @override
  Future<void> setPin(String newPin) => localDataSource.savePin(hashPin(newPin));

  @override
  Future<bool> isSecurityEnabled() => localDataSource.isSecurityEnabled();

  @override
  Future<void> setSecurityEnabled(bool enabled) =>
      localDataSource.setSecurityEnabled(enabled);

  @override
  Future<void> resetPinToDefault() =>
      localDataSource.savePin(hashPin(SecurityLocalDataSourceImpl.defaultPin));
}
