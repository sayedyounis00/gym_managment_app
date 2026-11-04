import '../repositories/security_repository.dart';

class VerifyPin {
  final SecurityRepository repository;

  VerifyPin(this.repository);

  Future<bool> call(String pin) => repository.verifyPin(pin);
}
