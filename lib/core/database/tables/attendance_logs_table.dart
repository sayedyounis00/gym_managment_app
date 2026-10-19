import 'package:drift/drift.dart';
import 'members_table.dart';
import 'subscriptions_table.dart';

@TableIndex(name: 'idx_attendance_logs_member_id', columns: {#memberId})
@TableIndex(name: 'idx_attendance_logs_subscription_id', columns: {#subscriptionId})
@TableIndex(name: 'idx_attendance_logs_attended_on', columns: {#attendedOn})
class AttendanceLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get memberId => integer().references(Members, #id, onDelete: KeyAction.cascade)();
  IntColumn get subscriptionId => integer().references(Subscriptions, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get attendedOn => dateTime()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column>> get uniqueKeys => [
        {subscriptionId, attendedOn},
      ];
}
