import 'package:flutter_test/flutter_test.dart';
import 'package:gym_managment_app/core/widgets/status_chip.dart';
import 'package:gym_managment_app/features/memberships/domain/entities/membership_package.dart';
import 'package:gym_managment_app/features/memberships/domain/entities/subscription.dart';
import 'package:gym_managment_app/features/memberships/domain/rules/membership_rules.dart';

void main() {
  group('MembershipRules.calculateEndDate Tests', () {
    test('adds days correctly', () {
      final start = DateTime(2026, 1, 10);
      final end = MembershipRules.calculateEndDate(
        startDate: start,
        durationValue: 30,
        durationUnit: 'days',
      );

      expect(end, DateTime(2026, 2, 9));
    });

    test('adds calendar months accurately with regular month', () {
      final start = DateTime(2026, 3, 15);
      final end = MembershipRules.calculateEndDate(
        startDate: start,
        durationValue: 1,
        durationUnit: 'months',
      );

      expect(end, DateTime(2026, 4, 15));
    });

    test('adds months with month-end clamping (Jan 31 -> Feb 28 on non-leap year)', () {
      final start = DateTime(2026, 1, 31);
      final end = MembershipRules.calculateEndDate(
        startDate: start,
        durationValue: 1,
        durationUnit: 'months',
      );

      expect(end, DateTime(2026, 2, 28));
    });

    test('adds months with month-end clamping on leap year (Jan 31 2024 -> Feb 29 2024)', () {
      final start = DateTime(2024, 1, 31);
      final end = MembershipRules.calculateEndDate(
        startDate: start,
        durationValue: 1,
        durationUnit: 'months',
      );

      expect(end, DateTime(2024, 2, 29));
    });

    test('adds multi-months across year boundary (Nov 15 2026 + 3 months -> Feb 15 2027)', () {
      final start = DateTime(2026, 11, 15);
      final end = MembershipRules.calculateEndDate(
        startDate: start,
        durationValue: 3,
        durationUnit: 'months',
      );

      expect(end, DateTime(2027, 2, 15));
    });

    test('clamps 31st to 30th on 30-day months (Aug 31 + 1 month -> Sep 30)', () {
      final start = DateTime(2026, 8, 31);
      final end = MembershipRules.calculateEndDate(
        startDate: start,
        durationValue: 1,
        durationUnit: 'months',
      );

      expect(end, DateTime(2026, 9, 30));
    });
  });

  group('MembershipRules.calculateRenewStartDate Tests', () {
    final now = DateTime(2026, 5, 10);

    test('returns today when no current subscription exists', () {
      final date = MembershipRules.calculateRenewStartDate(
        currentSubscription: null,
        now: now,
      );

      expect(date, DateTime(2026, 5, 10));
    });

    test('returns today when current subscription is expired', () {
      final sub = Subscription(
        id: 1,
        memberId: 10,
        packageNameSnapshot: 'شهر',
        priceSnapshot: 500,
        startDate: DateTime(2026, 4, 1),
        endDate: DateTime(2026, 5, 1), // expired 9 days ago
        status: 'expired',
        createdAt: DateTime(2026, 4, 1),
      );

      final date = MembershipRules.calculateRenewStartDate(
        currentSubscription: sub,
        now: now,
      );

      expect(date, DateTime(2026, 5, 10));
    });

    test('returns day after current end date when subscription is currently active', () {
      final sub = Subscription(
        id: 1,
        memberId: 10,
        packageNameSnapshot: 'شهر',
        priceSnapshot: 500,
        startDate: DateTime(2026, 5, 1),
        endDate: DateTime(2026, 5, 31), // active, ends in 21 days
        status: 'active',
        createdAt: DateTime(2026, 5, 1),
      );

      final date = MembershipRules.calculateRenewStartDate(
        currentSubscription: sub,
        now: now,
      );

      expect(date, DateTime(2026, 6, 1));
    });
  });

  group('MembershipRules Pause & Resume Tests', () {
    final sub = Subscription(
      id: 1,
      memberId: 10,
      packageNameSnapshot: '3 شهور',
      priceSnapshot: 1200,
      startDate: DateTime(2026, 5, 1),
      endDate: DateTime(2026, 8, 1),
      status: 'active',
      createdAt: DateTime(2026, 5, 1),
    );

    test('applyPause updates status to paused and sets pausedAt', () {
      final pauseDate = DateTime(2026, 5, 15);
      final paused = MembershipRules.applyPause(
        subscription: sub,
        pauseDate: pauseDate,
        reason: 'سفر لمدة أسبوعين',
      );

      expect(paused.status, 'paused');
      expect(paused.isPaused, isTrue);
      expect(paused.pausedAt, pauseDate);
      expect(paused.pauseReason, 'سفر لمدة أسبوعين');
    });

    test('applyPause throws if subscription is already expired', () {
      final expiredSub = sub.copyWith(
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2026, 2, 1),
      );

      expect(
        () => MembershipRules.applyPause(
          subscription: expiredSub,
          pauseDate: DateTime(2026, 5, 15),
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('applyResume shifts endDate by paused days and clears pause fields', () {
      final pauseDate = DateTime(2026, 5, 10);
      final paused = MembershipRules.applyPause(
        subscription: sub,
        pauseDate: pauseDate,
      );

      final resumeDate = DateTime(2026, 5, 20); // 10 days paused
      final resumed = MembershipRules.applyResume(
        subscription: paused,
        resumeDate: resumeDate,
      );

      expect(resumed.status, 'active');
      expect(resumed.isPaused, isFalse);
      expect(resumed.pausedAt, isNull);
      expect(resumed.pauseReason, isNull);
      expect(resumed.totalPausedDays, 10);
      expect(resumed.endDate, DateTime(2026, 8, 11)); // shifted by 10 days
    });
  });

  group('Subscription Entity Derived Values', () {
    final now = DateTime(2026, 5, 15);

    test('remainingDays, isExpiringSoon, and displayStatus', () {
      final activeSub = Subscription(
        id: 1,
        memberId: 1,
        packageNameSnapshot: 'شهر',
        priceSnapshot: 500,
        startDate: DateTime(2026, 5, 1),
        endDate: DateTime(2026, 5, 17), // 2 days left
        amountPaid: 500,
        createdAt: DateTime(2026, 5, 1),
      );

      expect(activeSub.remainingDays(now), 2);
      expect(activeSub.isExpiringSoon(now, 3), isTrue);
      expect(activeSub.displayStatus(now, 3), MemberStatusType.expiringSoon);
      expect(activeSub.remainingAmount, 0.0);
    });

    test('paused subscription displayStatus is paused even if past original endDate', () {
      final pausedSub = Subscription(
        id: 1,
        memberId: 1,
        packageNameSnapshot: 'شهر',
        priceSnapshot: 500,
        startDate: DateTime(2026, 4, 1),
        endDate: DateTime(2026, 5, 1),
        status: 'paused',
        pausedAt: DateTime(2026, 4, 20),
        amountPaid: 300,
        createdAt: DateTime(2026, 4, 1),
      );

      expect(pausedSub.displayStatus(now), MemberStatusType.paused);
      expect(pausedSub.remainingAmount, 200.0);
    });

    test('expired subscription displayStatus is expired', () {
      final expiredSub = Subscription(
        id: 1,
        memberId: 1,
        packageNameSnapshot: 'شهر',
        priceSnapshot: 500,
        startDate: DateTime(2026, 4, 1),
        endDate: DateTime(2026, 5, 1),
        status: 'active',
        amountPaid: 0,
        createdAt: DateTime(2026, 4, 1),
      );

      expect(expiredSub.displayStatus(now), MemberStatusType.expired);
      expect(expiredSub.remainingAmount, 500.0);
    });
  });

  group('MembershipPackage Entity Tests', () {
    test('formattedDuration handles singular, dual, and plural in Arabic', () {
      final p1 = MembershipPackage(
        id: 1,
        name: 'يوم',
        price: 50,
        durationValue: 1,
        durationUnit: 'days',
        createdAt: DateTime(2026, 1, 1),
      );
      expect(p1.formattedDuration, 'يوم واحد');

      final p2 = MembershipPackage(
        id: 2,
        name: 'يومان',
        price: 90,
        durationValue: 2,
        durationUnit: 'days',
        createdAt: DateTime(2026, 1, 1),
      );
      expect(p2.formattedDuration, 'يومان');

      final p3 = MembershipPackage(
        id: 3,
        name: 'أسبوع',
        price: 200,
        durationValue: 7,
        durationUnit: 'days',
        createdAt: DateTime(2026, 1, 1),
      );
      expect(p3.formattedDuration, '7 أيام');

      final p4 = MembershipPackage(
        id: 4,
        name: 'شهر',
        price: 500,
        durationValue: 1,
        durationUnit: 'months',
        createdAt: DateTime(2026, 1, 1),
      );
      expect(p4.formattedDuration, 'شهر واحد');

      final p5 = MembershipPackage(
        id: 5,
        name: 'شهران',
        price: 900,
        durationValue: 2,
        durationUnit: 'months',
        createdAt: DateTime(2026, 1, 1),
      );
      expect(p5.formattedDuration, 'شهران');

      final p6 = MembershipPackage(
        id: 6,
        name: 'ربع سنوي',
        price: 1300,
        durationValue: 3,
        durationUnit: 'months',
        createdAt: DateTime(2026, 1, 1),
      );
      expect(p6.formattedDuration, '3 شهور');

      final p7 = MembershipPackage(
        id: 7,
        name: 'سنوي',
        price: 4500,
        durationValue: 12,
        durationUnit: 'months',
        createdAt: DateTime(2026, 1, 1),
      );
      expect(p7.formattedDuration, 'سنة');
    });
  });
}
