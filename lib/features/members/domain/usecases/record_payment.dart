import 'package:fpdart/fpdart.dart';
import 'package:gym_managment_app/core/errors/failures.dart';
import '../repositories/members_repository.dart';

class RecordPaymentParams {
  final int memberId;
  final double amount;
  final String paymentMethod;
  final DateTime paidAt;
  final int? subscriptionId;
  final String? notes;

  const RecordPaymentParams({
    required this.memberId,
    required this.amount,
    required this.paymentMethod,
    required this.paidAt,
    this.subscriptionId,
    this.notes,
  });
}

class RecordPayment {
  final MembersRepository repository;

  RecordPayment(this.repository);

  Future<Either<Failure, Unit>> call(RecordPaymentParams params) {
    return repository.recordPayment(
      memberId: params.memberId,
      amount: params.amount,
      paymentMethod: params.paymentMethod,
      paidAt: params.paidAt,
      subscriptionId: params.subscriptionId,
      notes: params.notes,
    );
  }
}
