import 'package:drift/drift.dart';

@TableIndex(name: 'idx_members_name', columns: {#name})
@TableIndex(name: 'idx_members_phone', columns: {#phone})
@TableIndex(name: 'idx_members_status', columns: {#status})
class Members extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get phone => text().withLength(min: 1, max: 20)();
  TextColumn get photoPath => text().nullable()();
  IntColumn get age => integer().nullable()();
  RealColumn get weightKg => real().nullable()();
  RealColumn get heightCm => real().nullable()();
  BoolColumn get isSuspended => boolean().withDefault(const Constant(false))();
  TextColumn get status => text().withDefault(const Constant('active'))(); // kept for backward compatibility with DashboardDao
  TextColumn get searchName => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
