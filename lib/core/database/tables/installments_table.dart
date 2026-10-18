import 'package:drift/drift.dart';
import 'subscription_periods_table.dart';

@TableIndex(name: 'idx_installments_period_id', columns: {#periodId})
@TableIndex(name: 'idx_installments_due_date', columns: {#dueDate})
@TableIndex(name: 'idx_installments_status', columns: {#status})
class Installments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get periodId => integer().references(SubscriptionPeriods, #id)();
  IntColumn get installmentNumber => integer().withDefault(const Constant(1))();
  RealColumn get amount => real()();
  RealColumn get paidAmount => real().withDefault(const Constant(0.0))();
  DateTimeColumn get dueDate => dateTime()();
  TextColumn get status => text().withDefault(const Constant('pending'))(); // 'pending', 'paid'
  DateTimeColumn get paidAt => dateTime().nullable()();
  TextColumn get paymentMethod => text().nullable()(); // 'cash', 'card', 'transfer'
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
