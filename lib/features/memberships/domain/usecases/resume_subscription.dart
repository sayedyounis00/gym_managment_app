import 'package:fpdart/fpdart.dart';
import 'package:gym_managment_app/core/errors/failures.dart';
import '../repositories/memberships_repository.dart';

class ResumeSubscription {
  final MembershipsRepository repository;

  ResumeSubscription(this.repository);

  Future<Either<Failure, Unit>> call({
    required int memberId,
    required DateTime resumeDate,
  }) {
    if (memberId <= 0) {
      return Future.value(const Left(DatabaseFailure('معرف المشترك غير صالح')));
    }
    return repository.resumeSubscription(memberId, resumeDate);
  }
}
