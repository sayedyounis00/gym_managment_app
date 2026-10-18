import 'package:drift/drift.dart';
import 'subscriptions_table.dart';

@TableIndex(name: 'idx_subscription_periods_sub_id', columns: {#subscriptionId})
@TableIndex(name: 'idx_subscription_periods_dates', columns: {#startDate, #endDate})
@TableIndex(name: 'idx_subscription_periods_status', columns: {#paymentStatus})
class SubscriptionPeriods extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get subscriptionId => integer().references(Subscriptions, #id)();
  IntColumn get periodNumber => integer().withDefault(const Constant(1))();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime()();
  RealColumn get amountDue => real()();
  RealColumn get discount => real().withDefault(const Constant(0.0))();
  TextColumn get paymentStatus => text().withDefault(const Constant('unpaid'))(); // 'unpaid', 'partial', 'paid'
  BoolColumn get isFullyPaid => boolean().withDefault(const Constant(false))();
  DateTimeColumn get fullyPaidAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
