import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../entities/finance_enums.dart';
import '../repositories/payment_repository.dart';

class AddPaymentParams {
  final int memberId;
  final int? subscriptionId;
  final int? periodId;
  final int? installmentId;
  final double amount;
  final PaymentMethod? method;
  final DateTime paidAt;
  final String? note;

  const AddPaymentParams({
    required this.memberId,
    this.subscriptionId,
    this.periodId,
    this.installmentId,
    required this.amount,
    this.method,
    required this.paidAt,
    this.note,
  });
}

class AddPayment {
  final PaymentRepository repository;

  AddPayment(this.repository);

  Future<Either<Failure, int>> call(AddPaymentParams params) async {
    if (params.amount <= 0) {
      return const Left(ValidationFailure('يجب أن يكون مبلغ الدفعة أكبر من صفر'));
    }

    return repository.addPayment(
      memberId: params.memberId,
      subscriptionId: params.subscriptionId,
      periodId: params.periodId,
      installmentId: params.installmentId,
      amount: params.amount,
      method: params.method,
      paidAt: params.paidAt,
      note: params.note,
    );
  }
}
