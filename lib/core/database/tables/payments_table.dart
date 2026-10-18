import 'package:drift/drift.dart';
import 'members_table.dart';
import 'subscriptions_table.dart';
import 'subscription_periods_table.dart';
import 'installments_table.dart';

@TableIndex(name: 'idx_payments_paid_at', columns: {#paidAt})
@TableIndex(name: 'idx_payments_member_id', columns: {#memberId})
@TableIndex(name: 'idx_payments_installment_id', columns: {#installmentId})
@TableIndex(name: 'idx_payments_voided_at', columns: {#voidedAt})
class Payments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get memberId => integer().references(Members, #id)();
  IntColumn get subscriptionId => integer().nullable().references(Subscriptions, #id)();
  IntColumn get periodId => integer().nullable().references(SubscriptionPeriods, #id)();
  IntColumn get installmentId => integer().nullable().references(Installments, #id)();
  RealColumn get amount => real()();
  DateTimeColumn get paidAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get paymentMethod => text().withDefault(const Constant('cash'))(); // 'cash', 'transfer', 'wallet'
  TextColumn get notes => text().nullable()();
  TextColumn get memberNameSnapshot => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get voidedAt => dateTime().nullable()();
  TextColumn get voidReason => text().nullable()();
}
