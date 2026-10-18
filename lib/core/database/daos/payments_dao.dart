import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/payments_table.dart';
import '../tables/members_table.dart';
import '../tables/subscriptions_table.dart';
import '../tables/subscription_periods_table.dart';

part 'payments_dao.g.dart';

@DriftAccessor(tables: [
  Payments,
  Members,
  Subscriptions,
  SubscriptionPeriods,
])
class PaymentsDao extends DatabaseAccessor<AppDatabase> with _$PaymentsDaoMixin {
  PaymentsDao(super.db);

  Future<int> insertPayment(PaymentsCompanion payment) {
    return into(payments).insert(payment);
  }

  Future<Payment?> getPaymentById(int id) {
    return (select(payments)..where((p) => p.id.equals(id))).getSingleOrNull();
  }

  Future<bool> voidPayment(int id, {String? reason}) async {
    final rowsAffected = await (update(payments)..where((p) => p.id.equals(id))).write(
      PaymentsCompanion(
        voidedAt: Value(DateTime.now()),
        voidReason: Value(reason),
      ),
    );
    return rowsAffected > 0;
  }

  Stream<List<Payment>> watchPaymentsByMember(int memberId) {
    return (select(payments)
          ..where((p) => p.memberId.equals(memberId))
          ..orderBy([(p) => OrderingTerm.desc(p.paidAt)]))
        .watch();
  }

  Future<List<Payment>> getPaymentsByMember(int memberId) {
    return (select(payments)
          ..where((p) => p.memberId.equals(memberId))
          ..orderBy([(p) => OrderingTerm.desc(p.paidAt)]))
        .get();
  }

  Stream<List<Payment>> watchPaymentsBetween(DateTime from, DateTime to) {
    return (select(payments)
          ..where((p) =>
              p.paidAt.isBiggerOrEqualValue(from) &
              p.paidAt.isSmallerOrEqualValue(to))
          ..orderBy([(p) => OrderingTerm.desc(p.paidAt)]))
        .watch();
  }

  Future<double> sumBetween(DateTime from, DateTime to) async {
    final sum = payments.amount.sum();
    final query = selectOnly(payments)
      ..addColumns([sum])
      ..where(
        payments.paidAt.isBiggerOrEqualValue(from) &
        payments.paidAt.isSmallerOrEqualValue(to) &
        payments.voidedAt.isNull(),
      );
    final result = await query.map((row) => row.read(sum)).getSingle();
    return result ?? 0.0;
  }
}
