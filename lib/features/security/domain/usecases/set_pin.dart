import '../repositories/security_repository.dart';

class SetPin {
  final SecurityRepository repository;

  SetPin(this.repository);

  Future<void> call(String pin) => repository.setPin(pin);
}
