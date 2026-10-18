import 'package:drift/drift.dart';
import 'members_table.dart';
import 'subscriptions_table.dart';

@TableIndex(name: 'idx_payments_paid_at', columns: {#paidAt})
class Payments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get memberId => integer().references(Members, #id)();
  IntColumn get subscriptionId => integer().nullable().references(Subscriptions, #id)();
  RealColumn get amount => real()();
  DateTimeColumn get paidAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get paymentMethod => text().withDefault(const Constant('cash'))(); // 'cash', 'card', 'transfer'
  TextColumn get notes => text().nullable()();
}
