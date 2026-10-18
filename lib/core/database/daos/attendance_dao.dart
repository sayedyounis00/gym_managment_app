import 'package:drift/drift.dart';
import '../../utils/date_utils.dart';
import '../app_database.dart';
import '../tables/attendance_table.dart';

part 'attendance_dao.g.dart';

@DriftAccessor(tables: [Attendance])
class AttendanceDao extends DatabaseAccessor<AppDatabase> with _$AttendanceDaoMixin {
  AttendanceDao(super.db);

  Stream<List<AttendanceData>> watchAttendance(int memberId, DateTime month) {
    final startOfMonth = DateTime(month.year, month.month, 1);
    final nextMonth = month.month == 12
        ? DateTime(month.year + 1, 1, 1)
        : DateTime(month.year, month.month + 1, 1);

    return (select(attendance)
          ..where((a) =>
              a.memberId.equals(memberId) &
              a.checkInTime.isBiggerOrEqualValue(startOfMonth) &
              a.checkInTime.isSmallerThanValue(nextMonth))
          ..orderBy([(a) => OrderingTerm.desc(a.checkInTime)]))
        .watch();
  }

  Future<int> recordAttendance(int memberId, [DateTime? checkInTime]) {
    return into(attendance).insert(
      AttendanceCompanion.insert(
        memberId: memberId,
        checkInTime: Value(checkInTime ?? DateTime.now()),
      ),
    );
  }

  Future<bool> hasCheckedInToday(int memberId) async {
    final now = DateTime.now();
    final startOfToday = AppDateUtils.startOfDay(now);
    final endOfToday = AppDateUtils.endOfDay(now);

    final countExp = attendance.id.count();
    final query = selectOnly(attendance)
      ..addColumns([countExp])
      ..where(
        attendance.memberId.equals(memberId) &
        attendance.checkInTime.isBiggerOrEqualValue(startOfToday) &
        attendance.checkInTime.isSmallerOrEqualValue(endOfToday),
      );

    final result = await query.map((row) => row.read(countExp)).getSingle();
    return (result ?? 0) > 0;
  }

  Future<int> countTodayAttendance() async {
    final now = DateTime.now();
    final startOfToday = AppDateUtils.startOfDay(now);
    final endOfToday = AppDateUtils.endOfDay(now);

    final countExp = attendance.id.count();
    final query = selectOnly(attendance)
      ..addColumns([countExp])
      ..where(
        attendance.checkInTime.isBiggerOrEqualValue(startOfToday) &
        attendance.checkInTime.isSmallerOrEqualValue(endOfToday),
      );

    final result = await query.map((row) => row.read(countExp)).getSingle();
    return result ?? 0;
  }
}
