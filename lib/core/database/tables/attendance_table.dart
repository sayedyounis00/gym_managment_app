import 'package:drift/drift.dart';
import 'members_table.dart';

@TableIndex(name: 'idx_attendance_member_time', columns: {#memberId, #checkInTime})
class Attendance extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get memberId => integer().references(Members, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get checkInTime => dateTime().withDefault(currentDateAndTime)();
}
