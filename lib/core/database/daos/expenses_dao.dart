import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/expenses_table.dart';

part 'expenses_dao.g.dart';

@DriftAccessor(tables: [
  Expenses,
])
class ExpensesDao extends DatabaseAccessor<AppDatabase> with _$ExpensesDaoMixin {
  ExpensesDao(super.db);

  Future<int> insertExpense(ExpensesCompanion expense) {
    return into(expenses).insert(expense);
  }

  Future<bool> updateExpense(ExpensesCompanion expense) {
    return update(expenses).replace(expense);
  }

  Future<Expense?> getExpenseById(int id) {
    return (select(expenses)..where((e) => e.id.equals(id))).getSingleOrNull();
  }

  Future<bool> voidExpense(int id) async {
    final rowsAffected = await (update(expenses)..where((e) => e.id.equals(id))).write(
      ExpensesCompanion(
        voidedAt: Value(DateTime.now()),
      ),
    );
    return rowsAffected > 0;
  }

  Stream<List<Expense>> watchExpensesBetween(DateTime from, DateTime to) {
    return (select(expenses)
          ..where((e) =>
              e.date.isBiggerOrEqualValue(from) &
              e.date.isSmallerOrEqualValue(to))
          ..orderBy([(e) => OrderingTerm.desc(e.date)]))
        .watch();
  }

  Future<List<Expense>> getExpensesBetween(DateTime from, DateTime to) {
    return (select(expenses)
          ..where((e) =>
              e.date.isBiggerOrEqualValue(from) &
              e.date.isSmallerOrEqualValue(to))
          ..orderBy([(e) => OrderingTerm.desc(e.date)]))
        .get();
  }

  Future<double> sumBetween(DateTime from, DateTime to) async {
    final sum = expenses.amount.sum();
    final query = selectOnly(expenses)
      ..addColumns([sum])
      ..where(
        expenses.date.isBiggerOrEqualValue(from) &
        expenses.date.isSmallerOrEqualValue(to) &
        expenses.voidedAt.isNull(),
      );
    final result = await query.map((row) => row.read(sum)).getSingle();
    return result ?? 0.0;
  }
}
