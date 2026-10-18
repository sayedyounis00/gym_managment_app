import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../entities/finance_enums.dart';
import 'add_payment.dart';

class RecordFinancePayment {
  final AddPayment addPayment;

  RecordFinancePayment(this.addPayment);

  Future<Either<Failure, int>> call({
    required int memberId,
    int? subscriptionId,
    int? periodId,
    int? installmentId,
    required double amount,
    PaymentMethod? method,
    required DateTime paidAt,
    String? note,
  }) {
    return addPayment(
      AddPaymentParams(
        memberId: memberId,
        subscriptionId: subscriptionId,
        periodId: periodId,
        installmentId: installmentId,
        amount: amount,
        method: method,
        paidAt: paidAt,
        note: note,
      ),
    );
  }
}
