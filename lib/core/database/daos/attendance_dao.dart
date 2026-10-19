import 'package:drift/drift.dart';
import '../../utils/date_utils.dart';
import '../app_database.dart';
import '../tables/attendance_logs_table.dart';
import '../tables/members_table.dart';
import '../tables/subscriptions_table.dart';

part 'attendance_dao.g.dart';

@DriftAccessor(tables: [
  AttendanceLogs,
  Members,
  Subscriptions,
])
class AttendanceDao extends DatabaseAccessor<AppDatabase> with _$AttendanceDaoMixin {
  AttendanceDao(super.db);

  Stream<List<AttendanceLog>> watchAttendance(int subscriptionId) {
    return (select(attendanceLogs)
          ..where((tbl) => tbl.subscriptionId.equals(subscriptionId))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.attendedOn)]))
        .watch();
  }

  Stream<List<DateTime>> watchAttendanceDates(int subscriptionId) {
    return watchAttendance(subscriptionId).map(
      (logs) => logs.map((l) => l.attendedOn).toList(),
    );
  }

  Future<List<DateTime>> getAttendanceDates(int subscriptionId) async {
    final rows = await (select(attendanceLogs)
          ..where((tbl) => tbl.subscriptionId.equals(subscriptionId))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.attendedOn)]))
        .get();
    return rows.map((r) => r.attendedOn).toList();
  }

  Future<int> markAttendance(int memberId, int subscriptionId, DateTime date) {
    final normalized = AppDateUtils.startOfDay(date);
    return into(attendanceLogs).insert(
      AttendanceLogsCompanion.insert(
        memberId: memberId,
        subscriptionId: subscriptionId,
        attendedOn: normalized,
      ),
      mode: InsertMode.insertOrIgnore,
    );
  }

  Future<int> unmarkAttendance(int subscriptionId, DateTime date) {
    final normalized = AppDateUtils.startOfDay(date);
    return (delete(attendanceLogs)
          ..where((tbl) =>
              tbl.subscriptionId.equals(subscriptionId) &
              tbl.attendedOn.equals(normalized)))
        .go();
  }

  Future<int> countAttendance(int subscriptionId) async {
    final count = attendanceLogs.id.count();
    final query = selectOnly(attendanceLogs)
      ..addColumns([count])
      ..where(attendanceLogs.subscriptionId.equals(subscriptionId));
    final result = await query.map((r) => r.read(count)).getSingle();
    return result ?? 0;
  }

  Future<int> countCheckInsToday([DateTime? now]) async {
    final today = AppDateUtils.startOfDay(now ?? DateTime.now());
    final count = attendanceLogs.id.count();
    final query = selectOnly(attendanceLogs)
      ..addColumns([count])
      ..where(attendanceLogs.attendedOn.equals(today));
    final result = await query.map((r) => r.read(count)).getSingle();
    return result ?? 0;
  }

  Stream<int> watchCheckInsToday([DateTime? now]) {
    final today = AppDateUtils.startOfDay(now ?? DateTime.now());
    final count = attendanceLogs.id.count();
    final query = selectOnly(attendanceLogs)
      ..addColumns([count])
      ..where(attendanceLogs.attendedOn.equals(today));
    return query.map((r) => r.read(count) ?? 0).watchSingle();
  }
}
