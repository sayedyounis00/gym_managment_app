import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../entities/finance_enums.dart';
import '../repositories/expense_repository.dart';

class AddExpenseParams {
  final ExpenseCategory category;
  final String? customLabel;
  final double amount;
  final PaymentMethod? method;
  final DateTime date;
  final String? note;

  const AddExpenseParams({
    required this.category,
    this.customLabel,
    required this.amount,
    this.method,
    required this.date,
    this.note,
  });
}

class AddExpense {
  final ExpenseRepository repository;

  AddExpense(this.repository);

  Future<Either<Failure, int>> call(AddExpenseParams params) async {
    if (params.amount <= 0) {
      return const Left(ValidationFailure('يجب أن يكون مبلغ المصروف أكبر من صفر'));
    }

    if (params.category == ExpenseCategory.other &&
        (params.customLabel == null || params.customLabel!.trim().isEmpty)) {
      return const Left(ValidationFailure('يجب تحديد مسمى المصروف عند اختيار تصنيف "أخرى"'));
    }

    return repository.addExpense(
      category: params.category,
      customLabel: params.customLabel?.trim(),
      amount: params.amount,
      method: params.method,
      date: params.date,
      note: params.note?.trim(),
    );
  }
}
