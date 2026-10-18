import 'package:fpdart/fpdart.dart';
import 'package:gym_managment_app/core/errors/failures.dart';
import '../repositories/memberships_repository.dart';

class RenewSubscription {
  final MembershipsRepository repository;

  RenewSubscription(this.repository);

  Future<Either<Failure, int>> call(RenewParams params) {
    if (params.memberId <= 0) {
      return Future.value(const Left(DatabaseFailure('معرف المشترك غير صالح')));
    }
    if (params.packageId <= 0) {
      return Future.value(const Left(DatabaseFailure('يرجى اختيار باقة صالحة')));
    }
    if (params.endDate.isBefore(params.startDate)) {
      return Future.value(const Left(DatabaseFailure('تاريخ الانتهاء يجب أن يكون بعد تاريخ البدء')));
    }
    if (params.amountPaid < 0) {
      return Future.value(const Left(DatabaseFailure('المبلغ المدفوع لا يمكن أن يكون سالباً')));
    }
    return repository.renewSubscription(params);
  }
}
