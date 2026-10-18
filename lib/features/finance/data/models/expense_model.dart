import '../../../../core/database/app_database.dart' as db;
import '../../domain/entities/expense.dart';
import '../../domain/entities/finance_enums.dart';

class ExpenseModel {
  static Expense fromDrift(db.Expense row) {
    return Expense(
      id: row.id,
      category: ExpenseCategory.fromString(row.category),
      customLabel: row.customLabel,
      amount: row.amount,
      method: PaymentMethod.fromString(row.paymentMethod),
      date: row.date,
      note: row.notes,
      createdAt: row.createdAt,
      voidedAt: row.voidedAt,
    );
  }
}
