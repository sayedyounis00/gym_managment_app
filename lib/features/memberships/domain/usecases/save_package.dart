import 'package:fpdart/fpdart.dart';
import 'package:gym_managment_app/core/errors/failures.dart';
import '../entities/membership_package.dart';
import '../repositories/memberships_repository.dart';

class SavePackage {
  final MembershipsRepository repository;

  SavePackage(this.repository);

  Future<Either<Failure, int>> call(MembershipPackage package) {
    if (package.name.trim().isEmpty) {
      return Future.value(const Left(DatabaseFailure('اسم الباقة مطلوب')));
    }
    if (package.price <= 0) {
      return Future.value(const Left(DatabaseFailure('السعر يجب أن يكون أكبر من صفر')));
    }
    if (!package.isPayAsYouGo && package.durationValue <= 0) {
      return Future.value(const Left(DatabaseFailure('المدة يجب أن تكون يوماً واحداً على الأقل')));
    }
    return repository.savePackage(package);
  }
}
