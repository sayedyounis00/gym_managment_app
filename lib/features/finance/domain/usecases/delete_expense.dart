import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import 'void_expense.dart';

class DeleteExpense {
  final VoidExpense voidExpense;

  DeleteExpense(this.voidExpense);

  Future<Either<Failure, Unit>> call(int expenseId) {
    return voidExpense(expenseId);
  }
}
