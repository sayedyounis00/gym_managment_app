import '../repositories/security_repository.dart';

class IsLockEnabled {
  final SecurityRepository repository;

  IsLockEnabled(this.repository);

  Future<bool> call() => repository.isSecurityEnabled();
}
