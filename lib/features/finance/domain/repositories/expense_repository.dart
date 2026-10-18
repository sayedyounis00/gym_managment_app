import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../entities/expense.dart';
import '../entities/finance_enums.dart';

abstract class ExpenseRepository {
  Future<Either<Failure, int>> addExpense({
    required ExpenseCategory category,
    String? customLabel,
    required double amount,
    PaymentMethod? method,
    required DateTime date,
    String? note,
  });

  Future<Either<Failure, Unit>> updateExpense(
    int expenseId, {
    required ExpenseCategory category,
    String? customLabel,
    required double amount,
    PaymentMethod? method,
    required DateTime date,
    String? note,
  });

  Future<Either<Failure, Unit>> voidExpense(int expenseId);

  Stream<List<Expense>> watchExpenses({
    DateTime? from,
    DateTime? to,
  });

  Future<Either<Failure, List<Expense>>> getExpenses({
    DateTime? from,
    DateTime? to,
  });
}
