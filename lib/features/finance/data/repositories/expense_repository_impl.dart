import 'package:drift/drift.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/database/app_database.dart' hide Expense;
import '../../../../core/database/daos/expenses_dao.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/finance_enums.dart';
import '../../domain/repositories/expense_repository.dart';
import '../models/expense_model.dart';

class ExpenseRepositoryImpl implements ExpenseRepository {
  final ExpensesDao expensesDao;

  ExpenseRepositoryImpl({required this.expensesDao});

  @override
  Future<Either<Failure, int>> addExpense({
    required ExpenseCategory category,
    String? customLabel,
    required double amount,
    PaymentMethod? method,
    required DateTime date,
    String? note,
  }) async {
    try {
      final id = await expensesDao.insertExpense(
        ExpensesCompanion.insert(
          category: Value(category.value),
          customLabel: Value(customLabel),
          title: customLabel ?? category.labelArabic,
          amount: amount,
          paymentMethod: Value(method?.value),
          date: Value(date),
          notes: Value(note),
          createdAt: Value(DateTime.now()),
        ),
      );
      return Right(id);
    } catch (e) {
      return Left(DatabaseFailure('فشل إضافة المصروف: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateExpense(
    int expenseId, {
    required ExpenseCategory category,
    String? customLabel,
    required double amount,
    PaymentMethod? method,
    required DateTime date,
    String? note,
  }) async {
    try {
      final existing = await expensesDao.getExpenseById(expenseId);
      if (existing == null) {
        return const Left(DatabaseFailure('المصروف غير موجود'));
      }

      final success = await expensesDao.updateExpense(
        ExpensesCompanion(
          id: Value(expenseId),
          category: Value(category.value),
          customLabel: Value(customLabel),
          title: Value(customLabel ?? category.labelArabic),
          amount: Value(amount),
          paymentMethod: Value(method?.value),
          date: Value(date),
          notes: Value(note),
          createdAt: Value(existing.createdAt),
          voidedAt: Value(existing.voidedAt),
        ),
      );

      if (!success) {
        return const Left(DatabaseFailure('فشل تحديث بيانات المصروف'));
      }
      return const Right(unit);
    } catch (e) {
      return Left(DatabaseFailure('فشل تحديث المصروف: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> voidExpense(int expenseId) async {
    try {
      final success = await expensesDao.voidExpense(expenseId);
      if (!success) {
        return const Left(DatabaseFailure('فشل إلغاء المصروف'));
      }
      return const Right(unit);
    } catch (e) {
      return Left(DatabaseFailure('فشل إلغاء المصروف: $e'));
    }
  }

  @override
  Stream<List<Expense>> watchExpenses({DateTime? from, DateTime? to}) {
    final start = from ?? DateTime(2000);
    final end = to ?? DateTime(2100);
    return expensesDao
        .watchExpensesBetween(start, end)
        .map((rows) => rows.map(ExpenseModel.fromDrift).toList());
  }

  @override
  Future<Either<Failure, List<Expense>>> getExpenses({DateTime? from, DateTime? to}) async {
    try {
      final start = from ?? DateTime(2000);
      final end = to ?? DateTime(2100);
      final rows = await expensesDao.getExpensesBetween(start, end);
      return Right(rows.map(ExpenseModel.fromDrift).toList());
    } catch (e) {
      return Left(DatabaseFailure('فشل استرجاع المصروفات: $e'));
    }
  }
}
