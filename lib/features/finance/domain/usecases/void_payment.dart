import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/payment_repository.dart';

class VoidPayment {
  final PaymentRepository repository;

  VoidPayment(this.repository);

  Future<Either<Failure, Unit>> call(int paymentId, {String? reason}) {
    return repository.voidPayment(paymentId, reason: reason);
  }
}
