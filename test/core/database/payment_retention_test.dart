import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_managment_app/core/database/app_database.dart';
import 'package:gym_managment_app/core/database/daos/members_dao.dart';
import 'package:gym_managment_app/core/database/daos/payments_dao.dart';

void main() {
  late AppDatabase db;
  late MembersDao membersDao;
  late PaymentsDao paymentsDao;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    membersDao = MembersDao(db);
    paymentsDao = PaymentsDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('Payment Retention & Cleanup Tests', () {
    test('getPaymentRetentionCutoff computes beginning of month 3 months prior', () {
      final refDate = DateTime(2026, 10, 28);
      final cutoff = membersDao.getPaymentRetentionCutoff(refDate);

      expect(cutoff.year, equals(2026));
      expect(cutoff.month, equals(7)); // 10 - 3 = 7 (July)
      expect(cutoff.day, equals(1));
    });

    test('getMemberPayments purges payments older than 3 months and retains current + last 3 months', () async {
      final memberId = await db.into(db.members).insert(
            MembersCompanion.insert(
              name: 'Ahmed Ali',
              phone: '01012345678',
              status: const Value('active'),
            ),
          );

      final now = DateTime.now();
      final currentMonthDate = DateTime(now.year, now.month, 10);
      final twoMonthsAgo = DateTime(now.year, now.month - 2, 15);
      final threeMonthsAgo = DateTime(now.year, now.month - 3, 5);
      final fourMonthsAgo = DateTime(now.year, now.month - 4, 1);
      final fiveMonthsAgo = DateTime(now.year, now.month - 5, 20);

      // Insert payments across different months
      await db.into(db.payments).insert(PaymentsCompanion.insert(
            memberId: memberId,
            amount: 100.0,
            paidAt: Value(currentMonthDate),
          ));
      await db.into(db.payments).insert(PaymentsCompanion.insert(
            memberId: memberId,
            amount: 200.0,
            paidAt: Value(twoMonthsAgo),
          ));
      await db.into(db.payments).insert(PaymentsCompanion.insert(
            memberId: memberId,
            amount: 300.0,
            paidAt: Value(threeMonthsAgo),
          ));
      await db.into(db.payments).insert(PaymentsCompanion.insert(
            memberId: memberId,
            amount: 400.0,
            paidAt: Value(fourMonthsAgo),
          ));
      await db.into(db.payments).insert(PaymentsCompanion.insert(
            memberId: memberId,
            amount: 500.0,
            paidAt: Value(fiveMonthsAgo),
          ));

      // Fetch member payments via MembersDao
      final results = await membersDao.getMemberPayments(memberId);

      // Payments from 4 and 5 months ago must be deleted.
      // Payments from current month, 2 months ago, and 3 months ago must be kept.
      expect(results.length, equals(3));
      final amounts = results.map((p) => p.amount).toList();
      expect(amounts, containsAll([100.0, 200.0, 300.0]));
      expect(amounts, isNot(contains(400.0)));
      expect(amounts, isNot(contains(500.0)));

      // Verify the records were actually deleted from the database table
      final allDbPayments = await (db.select(db.payments)..where((p) => p.memberId.equals(memberId))).get();
      expect(allDbPayments.length, equals(3));
    });

    test('PaymentsDao.getPaymentsByMember purges payments older than 3 months', () async {
      final memberId = await db.into(db.members).insert(
            MembersCompanion.insert(
              name: 'Sara Nour',
              phone: '01099998888',
              status: const Value('active'),
            ),
          );

      final now = DateTime.now();
      final currentMonthDate = DateTime(now.year, now.month, 1);
      final oldDate = DateTime(now.year, now.month - 4, 1);

      await db.into(db.payments).insert(PaymentsCompanion.insert(
            memberId: memberId,
            amount: 150.0,
            paidAt: Value(currentMonthDate),
          ));
      await db.into(db.payments).insert(PaymentsCompanion.insert(
            memberId: memberId,
            amount: 250.0,
            paidAt: Value(oldDate),
          ));

      final payments = await paymentsDao.getPaymentsByMember(memberId);

      expect(payments.length, equals(1));
      expect(payments.first.amount, equals(150.0));
    });

    test('cleanupPaymentsOlderThanThreeMonths cleans up all members old payments globally', () async {
      final m1 = await db.into(db.members).insert(
            MembersCompanion.insert(
              name: 'Member 1',
              phone: '01011111111',
              status: const Value('active'),
            ),
          );
      final m2 = await db.into(db.members).insert(
            MembersCompanion.insert(
              name: 'Member 2',
              phone: '01022222222',
              status: const Value('active'),
            ),
          );

      final now = DateTime.now();
      final currentMonthDate = DateTime(now.year, now.month, 2);
      final oldDate = DateTime(now.year, now.month - 6, 1);

      await db.into(db.payments).insert(PaymentsCompanion.insert(
            memberId: m1,
            amount: 100.0,
            paidAt: Value(currentMonthDate),
          ));
      await db.into(db.payments).insert(PaymentsCompanion.insert(
            memberId: m1,
            amount: 200.0,
            paidAt: Value(oldDate),
          ));
      await db.into(db.payments).insert(PaymentsCompanion.insert(
            memberId: m2,
            amount: 300.0,
            paidAt: Value(oldDate),
          ));

      final deletedCount = await db.cleanupPaymentsOlderThanThreeMonths();
      expect(deletedCount, equals(2));

      final remaining = await db.select(db.payments).get();
      expect(remaining.length, equals(1));
      expect(remaining.first.memberId, equals(m1));
      expect(remaining.first.amount, equals(100.0));
    });
  });
}
