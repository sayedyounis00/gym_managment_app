import 'package:drift/drift.dart';

class Packages extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  RealColumn get price => real()();
  IntColumn get durationValue => integer().withDefault(const Constant(30))();
  TextColumn get durationUnit => text().withDefault(const Constant('days'))(); // 'days' | 'months'
  IntColumn get durationInDays => integer()(); // backwards compatibility
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
