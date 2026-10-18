import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../entities/finance_enums.dart';
import '../entities/payment.dart';

abstract class PaymentRepository {
  Future<Either<Failure, int>> addPayment({
    required int memberId,
    int? subscriptionId,
    int? periodId,
    int? installmentId,
    required double amount,
    PaymentMethod? method,
    required DateTime paidAt,
    String? note,
  });

  Future<Either<Failure, Unit>> voidPayment(
    int paymentId, {
    String? reason,
  });

  Stream<List<Payment>> watchMemberPayments(int memberId);

  Future<Either<Failure, List<Payment>>> getMemberPayments(int memberId);
}
