import 'package:drift/drift.dart';
import 'members_table.dart';
import 'packages_table.dart';

@TableIndex(name: 'idx_subscriptions_end_date', columns: {#endDate})
@TableIndex(name: 'idx_subscriptions_start_date', columns: {#startDate})
@TableIndex(name: 'idx_subscriptions_status', columns: {#status})
@TableIndex(name: 'idx_subscriptions_member_id', columns: {#memberId})
class Subscriptions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get memberId => integer().references(Members, #id)();
  IntColumn get packageId => integer().nullable().references(Packages, #id)();
  TextColumn get packageNameSnapshot => text().nullable()();
  RealColumn get priceSnapshot => real().nullable()();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime()();
  BoolColumn get isRenewal => boolean().withDefault(const Constant(false))();
  TextColumn get status => text().withDefault(const Constant('active'))(); // 'active', 'expired', 'paused'
  DateTimeColumn get pausedAt => dateTime().nullable()();
  TextColumn get pauseReason => text().nullable()();
  IntColumn get totalPausedDays => integer().withDefault(const Constant(0))();
  BoolColumn get trackAttendance => boolean().withDefault(const Constant(false))();
  RealColumn get amountPaid => real().withDefault(const Constant(0.0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
