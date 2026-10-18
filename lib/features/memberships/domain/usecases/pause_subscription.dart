import 'package:fpdart/fpdart.dart';
import 'package:gym_managment_app/core/errors/failures.dart';
import '../repositories/memberships_repository.dart';

class PauseSubscription {
  final MembershipsRepository repository;

  PauseSubscription(this.repository);

  Future<Either<Failure, Unit>> call(PauseParams params) {
    if (params.memberId <= 0) {
      return Future.value(const Left(DatabaseFailure('معرف المشترك غير صالح')));
    }
    return repository.pauseSubscription(params);
  }
}
