import 'package:drift/drift.dart';
import 'members_table.dart';

@TableIndex(name: 'idx_member_notes_member_id', columns: {#memberId})
class MemberNotes extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get memberId => integer().references(Members, #id, onDelete: KeyAction.cascade)();
  TextColumn get note => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
