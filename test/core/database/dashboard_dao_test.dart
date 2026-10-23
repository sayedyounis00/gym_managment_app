import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_managment_app/core/database/app_database.dart';
import 'package:gym_managment_app/core/database/daos/dashboard_dao.dart';
import 'package:gym_managment_app/core/utils/date_utils.dart';

Future<void> _populateDashboardTestData(AppDatabase db) async {
  final now = DateTime.now();

  final pkgMonthlyId = await db.into(db.packages).insert(
        PackagesCompanion.insert(
          name: 'Monthly Standard',
          durationInDays: 30,
          price: 50.0,
        ),
      );

  final pkgQuarterlyId = await db.into(db.packages).insert(
        PackagesCompanion.insert(
          name: 'Quarterly Pro',
          durationInDays: 90,
          price: 130.0,
        ),
      );

  final pkgAnnualId = await db.into(db.packages).insert(
        PackagesCompanion.insert(
          name: 'Annual VIP',
          durationInDays: 365,
          price: 450.0,
        ),
      );

  final m1 = await db.into(db.members).insert(
        MembersCompanion.insert(
          name: 'John Doe',
          phone: '+15551234567',
          status: const Value('active'),
        ),
      );

  final m2 = await db.into(db.members).insert(
        MembersCompanion.insert(
          name: 'Sarah Connor',
          phone: '+15559876543',
          status: const Value('active'),
        ),
      );

  final m3 = await db.into(db.members).insert(
        MembersCompanion.insert(
          name: 'Mike Tyson',
          phone: '+15553334444',
          status: const Value('active'),
        ),
      );

  final m4 = await db.into(db.members).insert(
        MembersCompanion.insert(
          name: 'Emily Watson',
          phone: '+15557778888',
          status: const Value('active'),
        ),
      );

  final m5 = await db.into(db.members).insert(
        MembersCompanion.insert(
          name: 'Robert Paulson',
          phone: '+15556667777',
          status: const Value('paused'),
        ),
      );

  final m6 = await db.into(db.members).insert(
        MembersCompanion.insert(
          name: 'Bruce Wayne',
          phone: '+15551112222',
          status: const Value('active'),
        ),
      );

  final m7 = await db.into(db.members).insert(
        MembersCompanion.insert(
          name: 'Diana Prince',
          phone: '+15554445555',
          status: const Value('active'),
        ),
      );

  await db.into(db.members).insert(
        MembersCompanion.insert(
          name: 'Clark Kent',
          phone: '+15558889999',
          status: const Value('inactive'),
        ),
      );

  final sub1 = await db.into(db.subscriptions).insert(
        SubscriptionsCompanion.insert(
          memberId: m1,
          packageId: Value(pkgMonthlyId),
          startDate: now.subtract(const Duration(days: 30)),
          endDate: DateTime(now.year, now.month, now.day, 23, 59, 59),
          isRenewal: const Value(false),
          status: const Value('active'),
        ),
      );

  final sub2 = await db.into(db.subscriptions).insert(
        SubscriptionsCompanion.insert(
          memberId: m2,
          packageId: Value(pkgMonthlyId),
          startDate: now.subtract(const Duration(days: 27)),
          endDate: now.add(const Duration(days: 3)),
          isRenewal: const Value(true),
          status: const Value('active'),
        ),
      );

  await db.into(db.subscriptions).insert(
        SubscriptionsCompanion.insert(
          memberId: m3,
          packageId: Value(pkgMonthlyId),
          startDate: now.subtract(const Duration(days: 24)),
          endDate: now.add(const Duration(days: 6)),
          isRenewal: const Value(false),
          status: const Value('active'),
        ),
      );

  final sub4 = await db.into(db.subscriptions).insert(
        SubscriptionsCompanion.insert(
          memberId: m4,
          packageId: Value(pkgMonthlyId),
          startDate: now.subtract(const Duration(days: 5)),
          endDate: now.add(const Duration(days: 25)),
          isRenewal: const Value(false),
          status: const Value('active'),
        ),
      );

  await db.into(db.subscriptions).insert(
        SubscriptionsCompanion.insert(
          memberId: m5,
          packageId: Value(pkgMonthlyId),
          startDate: now.subtract(const Duration(days: 28)),
          endDate: now.add(const Duration(days: 2)),
          isRenewal: const Value(false),
          status: const Value('paused'),
        ),
      );

  final sub6 = await db.into(db.subscriptions).insert(
        SubscriptionsCompanion.insert(
          memberId: m6,
          packageId: Value(pkgQuarterlyId),
          startDate: now.subtract(const Duration(days: 10)),
          endDate: now.add(const Duration(days: 80)),
          isRenewal: const Value(false),
          status: const Value('active'),
        ),
      );

  final sub7 = await db.into(db.subscriptions).insert(
        SubscriptionsCompanion.insert(
          memberId: m7,
          packageId: Value(pkgAnnualId),
          startDate: now.subtract(const Duration(days: 2)),
          endDate: now.add(const Duration(days: 363)),
          isRenewal: const Value(false),
          status: const Value('active'),
        ),
      );

  await db.into(db.payments).insert(
        PaymentsCompanion.insert(
          memberId: m4,
          subscriptionId: Value(sub4),
          amount: 50.0,
          paidAt: Value(now),
          paymentMethod: const Value('cash'),
        ),
      );

  await db.into(db.payments).insert(
        PaymentsCompanion.insert(
          memberId: m7,
          subscriptionId: Value(sub7),
          amount: 450.0,
          paidAt: Value(now),
          paymentMethod: const Value('card'),
        ),
      );

  await db.into(db.payments).insert(
        PaymentsCompanion.insert(
          memberId: m6,
          subscriptionId: Value(sub6),
          amount: 130.0,
          paidAt: Value(now.subtract(const Duration(days: 10))),
          paymentMethod: const Value('card'),
        ),
      );

  await db.into(db.payments).insert(
        PaymentsCompanion.insert(
          memberId: m2,
          subscriptionId: Value(sub2),
          amount: 50.0,
          paidAt: Value(now.subtract(const Duration(days: 27))),
          paymentMethod: const Value('cash'),
        ),
      );

  await db.into(db.payments).insert(
        PaymentsCompanion.insert(
          memberId: m1,
          subscriptionId: Value(sub1),
          amount: 50.0,
          paidAt: Value(now.subtract(const Duration(days: 30))),
          paymentMethod: const Value('cash'),
        ),
      );

  await db.into(db.expenses).insert(
        ExpensesCompanion.insert(
          title: 'Electricity & Utility Bill',
          category: const Value('utilities'),
          amount: 140.0,
          date: Value(now.subtract(const Duration(days: 8))),
        ),
      );

  await db.into(db.expenses).insert(
        ExpensesCompanion.insert(
          title: 'Treadmill Belt Maintenance',
          category: const Value('maintenance'),
          amount: 95.0,
          date: Value(now.subtract(const Duration(days: 4))),
        ),
      );

  await db.into(db.expenses).insert(
        ExpensesCompanion.insert(
          title: 'Gym Cleaning Supplies',
          category: const Value('supplies'),
          amount: 45.0,
          date: Value(now.subtract(const Duration(days: 1))),
        ),
      );
}

void main() {
  late AppDatabase db;
  late DashboardDao dao;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    dao = db.dashboardDao;
    await _populateDashboardTestData(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('DashboardDao Drift In-Memory Tests', () {
    test('countActiveMembers counts only members with status active', () async {
      final count = await dao.countActiveMembers();
      expect(count, equals(6));
    });

    test('getExpiringSubscriptions includes today and within 7 days, but excludes paused members', () async {
      final now = DateTime.now();
      final expiring = await dao.getExpiringSubscriptions(now: now, windowDays: 7);

      expect(expiring.length, equals(3));

      final names = expiring.map((e) => e.memberName).toList();
      expect(names, containsAll(['John Doe', 'Sarah Connor', 'Mike Tyson']));
      expect(names, isNot(contains('Robert Paulson')));
      expect(names, isNot(contains('Emily Watson')));

      final john = expiring.firstWhere((e) => e.memberName == 'John Doe');
      expect(john.daysLeft, equals(0));
    });

    test('getExpiringSubscriptions excludes suspended members even if subscription expires within 7 days', () async {
      final now = DateTime.now();

      // Suspend John Doe who is currently in expiring
      await (db.update(db.members)..where((tbl) => tbl.name.equals('John Doe'))).write(
        const MembersCompanion(isSuspended: Value(true)),
      );

      final expiring = await dao.getExpiringSubscriptions(now: now, windowDays: 7);
      final names = expiring.map((e) => e.memberName).toList();

      expect(names, isNot(contains('John Doe')));
      expect(names, containsAll(['Sarah Connor', 'Mike Tyson']));
      expect(expiring.length, equals(2));
    });

    test('countNewSubscriptions counts new subscriptions in rolling 30 days excluding renewals and paused members', () async {
      final now = DateTime.now();
      final (since, until) = AppDateUtils.rollingMonthWindow(now);

      final count = await dao.countNewSubscriptions(since: since, until: until);
      expect(count, equals(5));
    });

    test('sumRevenue and sumExpenses aggregate rolling 30-day amounts', () async {
      final now = DateTime.now();
      final (since, until) = AppDateUtils.rollingMonthWindow(now);

      final revenue = await dao.sumRevenue(since: since, until: until);
      expect(revenue, equals(730.0));

      final expenses = await dao.sumExpenses(since: since, until: until);
      expect(expenses, equals(280.0));

      final todayRev = await dao.sumTodayRevenue(now);
      expect(todayRev, equals(500.0));
    });
  });
}
