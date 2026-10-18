import 'package:fpdart/fpdart.dart';
import 'package:gym_managment_app/core/errors/failures.dart';
import 'package:gym_managment_app/core/usecases/usecase.dart';
import '../repositories/memberships_repository.dart';

class DeleteSubscription implements UseCase<Unit, int> {
  final MembershipsRepository repository;

  DeleteSubscription(this.repository);

  @override
  Future<Either<Failure, Unit>> call(int subscriptionId) {
    if (subscriptionId <= 0) {
      return Future.value(const Left(DatabaseFailure('معرف الاشتراك غير صالح')));
    }
    return repository.deleteSubscription(subscriptionId);
  }
}
