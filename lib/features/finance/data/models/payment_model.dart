import '../../../../core/database/app_database.dart' as db;
import '../../domain/entities/finance_enums.dart';
import '../../domain/entities/payment.dart';

class PaymentModel {
  static Payment fromDrift(db.Payment row, {String? memberName}) {
    return Payment(
      id: row.id,
      memberId: row.memberId,
      memberName: memberName ?? row.memberNameSnapshot,
      subscriptionId: row.subscriptionId,
      periodId: row.periodId,
      installmentId: row.installmentId,
      amount: row.amount,
      method: PaymentMethod.fromString(row.paymentMethod),
      paidAt: row.paidAt,
      note: row.notes,
      createdAt: row.createdAt,
      voidedAt: row.voidedAt,
      voidReason: row.voidReason,
    );
  }
}
