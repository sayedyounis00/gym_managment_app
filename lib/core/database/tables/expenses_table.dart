import 'package:drift/drift.dart';

@TableIndex(name: 'idx_expenses_date', columns: {#date})
@TableIndex(name: 'idx_expenses_category', columns: {#category})
@TableIndex(name: 'idx_expenses_voided_at', columns: {#voidedAt})
class Expenses extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 150)();
  TextColumn get category => text().withDefault(const Constant('general'))(); // 'rent', 'electricity', 'water', 'maintenance', 'other'
  TextColumn get customLabel => text().nullable()();
  RealColumn get amount => real()();
  TextColumn get paymentMethod => text().nullable()(); // 'cash', 'transfer', 'wallet'
  DateTimeColumn get date => dateTime().withDefault(currentDateAndTime)();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get voidedAt => dateTime().nullable()();
}
