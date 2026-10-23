import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_managment_app/core/database/app_database.dart';
import 'package:gym_managment_app/core/database/daos/attendance_dao.dart';
import 'package:gym_managment_app/core/utils/date_utils.dart';
import 'package:gym_managment_app/features/members/presentation/cubit/attendance/attendance_cubit.dart';

void main() {
  group('AppDateUtils Arabic Month Number Tests', () {
    test('arabicMonthWithNumber returns parenthesized month number before Arabic name', () {
      expect(AppDateUtils.arabicMonthWithNumber(1), equals('(1) يناير'));
      expect(AppDateUtils.arabicMonthWithNumber(2), equals('(2) فبراير'));
      expect(AppDateUtils.arabicMonthWithNumber(3), equals('(3) مارس'));
      expect(AppDateUtils.arabicMonthWithNumber(4), equals('(4) أبريل'));
      expect(AppDateUtils.arabicMonthWithNumber(5), equals('(5) مايو'));
      expect(AppDateUtils.arabicMonthWithNumber(6), equals('(6) يونيو'));
      expect(AppDateUtils.arabicMonthWithNumber(7), equals('(7) يوليو'));
      expect(AppDateUtils.arabicMonthWithNumber(8), equals('(8) أغسطس'));
      expect(AppDateUtils.arabicMonthWithNumber(9), equals('(9) سبتمبر'));
      expect(AppDateUtils.arabicMonthWithNumber(10), equals('(10) أكتوبر'));
      expect(AppDateUtils.arabicMonthWithNumber(11), equals('(11) نوفمبر'));
      expect(AppDateUtils.arabicMonthWithNumber(12), equals('(12) ديسمبر'));
    });

    test('formatShortDate formats as day (month_num) month_name year', () {
      final date = DateTime(2026, 10, 22);
      expect(AppDateUtils.formatShortDate(date), equals('22 (10) أكتوبر 2026'));
    });

    test('formatMonthYear formats as (month_num) month_name year', () {
      final date = DateTime(2026, 1, 15);
      expect(AppDateUtils.formatMonthYear(date), equals('(1) يناير 2026'));
    });

    test('formatDateTime contains month number and name', () {
      final date = DateTime(2026, 12, 5, 14, 30);
      expect(AppDateUtils.formatDateTime(date), contains('(12) ديسمبر 2026'));
    });
  });

  group('AttendanceDao & Cubit Tests', () {
    late AppDatabase db;
    late AttendanceDao attendanceDao;
    late int memberId;
    late int subscriptionId;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      attendanceDao = AttendanceDao(db);

      memberId = await db.into(db.members).insert(
            MembersCompanion.insert(
              name: 'Ali Hassan',
              phone: '01012345678',
              status: const Value('active'),
            ),
          );

      final packageId = await db.into(db.packages).insert(
            PackagesCompanion.insert(
              name: 'Daily Plan',
              durationValue: const Value(1),
              durationUnit: const Value('days'),
              durationInDays: 1,
              price: 20.0,
            ),
          );

      subscriptionId = await db.into(db.subscriptions).insert(
            SubscriptionsCompanion.insert(
              memberId: memberId,
              packageId: Value(packageId),
              startDate: DateTime(2026, 10, 1),
              endDate: DateTime(2026, 10, 2),
              amountPaid: const Value(20.0),
            ),
          );
    });

    tearDown(() async {
      await db.close();
    });

    test('toggleAttendance inserts attendance when not marked, and deletes when toggled again', () async {
      final targetDate = DateTime(2026, 10, 20);

      // Initially empty
      var dates = await attendanceDao.getMemberAttendanceDates(memberId);
      expect(dates, isEmpty);

      // Toggle ON
      await attendanceDao.toggleAttendance(
        memberId: memberId,
        subscriptionId: subscriptionId,
        date: targetDate,
      );

      dates = await attendanceDao.getMemberAttendanceDates(memberId);
      expect(dates.length, equals(1));
      expect(dates.first, equals(AppDateUtils.startOfDay(targetDate)));

      // Toggle OFF
      await attendanceDao.toggleAttendance(
        memberId: memberId,
        subscriptionId: subscriptionId,
        date: targetDate,
      );

      dates = await attendanceDao.getMemberAttendanceDates(memberId);
      expect(dates, isEmpty);
    });

    test('AttendanceCubit loads attendance dates and handles toggle', () async {
      final cubit = AttendanceCubit(attendanceDao: attendanceDao);
      cubit.init(memberId);

      // Wait for stream to deliver initial empty list
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(cubit.state.isLoading, isFalse);
      expect(cubit.state.attendedDates, isEmpty);

      final date = DateTime(2026, 10, 21);
      await cubit.toggleAttendance(
        memberId: memberId,
        subscriptionId: subscriptionId,
        date: date,
      );

      // Stream delivers the added date
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(cubit.state.attendedDates.length, equals(1));
      expect(cubit.state.attendedDates.first, equals(AppDateUtils.startOfDay(date)));

      await cubit.close();
    });
  });
}
