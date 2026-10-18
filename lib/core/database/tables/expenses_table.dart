import 'package:drift/drift.dart';

@TableIndex(name: 'idx_expenses_date', columns: {#date})
class Expenses extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 150)();
  TextColumn get category => text().withDefault(const Constant('general'))();
  RealColumn get amount => real()();
  DateTimeColumn get date => dateTime().withDefault(currentDateAndTime)();
  TextColumn get notes => text().nullable()();
}
