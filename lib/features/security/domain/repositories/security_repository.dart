abstract class SecurityRepository {
  Future<String> getPin();
  Future<bool> verifyPin(String pin);
  Future<void> setPin(String newPin);
  Future<bool> isSecurityEnabled();
  Future<void> setSecurityEnabled(bool enabled);
  Future<void> resetPinToDefault();
}
