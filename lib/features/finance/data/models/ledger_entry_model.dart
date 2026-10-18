import '../../../../core/database/daos/finance_dao.dart';
import '../../domain/entities/finance_enums.dart';
import '../../domain/entities/ledger_entry.dart';

class LedgerEntryModel {
  static LedgerEntry fromDao(RawLedgerRow row) {
    return LedgerEntry(
      id: row.id,
      originalId: row.originalId,
      type: row.type == 'income' ? LedgerType.income : LedgerType.expense,
      amount: row.amount,
      date: row.date,
      title: row.title,
      subtitle: row.subtitle,
      method: PaymentMethod.fromString(row.method),
      memberId: row.memberId,
      memberPhone: row.memberPhone,
      memberAvatarUrl: row.memberAvatarUrl,
      category: row.category != null ? ExpenseCategory.fromString(row.category!) : null,
      isVoided: row.isVoided,
      voidReason: row.voidReason,
    );
  }
}
