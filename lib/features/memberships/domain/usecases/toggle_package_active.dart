import 'package:fpdart/fpdart.dart';
import 'package:gym_managment_app/core/errors/failures.dart';
import '../repositories/memberships_repository.dart';

class TogglePackageActive {
  final MembershipsRepository repository;

  TogglePackageActive(this.repository);

  Future<Either<Failure, Unit>> call(int id, bool isActive) {
    return repository.setPackageActive(id, isActive);
  }
}

class DeletePackage {
  final MembershipsRepository repository;

  DeletePackage(this.repository);

  Future<Either<Failure, Unit>> call(int id) {
    return repository.deletePackage(id);
  }
}
