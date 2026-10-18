import 'package:fpdart/fpdart.dart';
import 'package:gym_managment_app/core/errors/failures.dart';
import '../entities/membership_package.dart';
import '../repositories/memberships_repository.dart';

class GetPackages {
  final MembershipsRepository repository;

  GetPackages(this.repository);

  Stream<List<MembershipPackage>> watch({bool activeOnly = false}) {
    return repository.watchPackages(activeOnly: activeOnly);
  }

  Future<Either<Failure, List<MembershipPackage>>> call({bool activeOnly = false}) {
    return repository.getPackages(activeOnly: activeOnly);
  }

  Future<Either<Failure, MembershipPackage>> getById(int id) {
    return repository.getPackageById(id);
  }
}
