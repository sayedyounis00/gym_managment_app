import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/expense_repository.dart';

class VoidExpense {
  final ExpenseRepository repository;

  VoidExpense(this.repository);

  Future<Either<Failure, Unit>> call(int expenseId) {
    return repository.voidExpense(expenseId);
  }
}
