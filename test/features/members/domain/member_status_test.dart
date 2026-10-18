import 'package:flutter_test/flutter_test.dart';
import 'package:gym_managment_app/core/widgets/status_chip.dart';
import 'package:gym_managment_app/features/members/domain/enums/member_status.dart';

void main() {
  group('resolveMemberStatus pure function tests', () {
    final fixedNow = DateTime(2026, 10, 18, 12, 0);

    test('returns paused when isSuspended is true regardless of dates', () {
      final status = resolveMemberStatus(
        isSuspended: true,
        subscriptionEndDate: fixedNow.add(const Duration(days: 30)),
        now: fixedNow,
      );
      expect(status, equals(MemberStatusType.paused));
    });

    test('returns expired when subscriptionEndDate is null', () {
      final status = resolveMemberStatus(
        isSuspended: false,
        subscriptionEndDate: null,
        now: fixedNow,
      );
      expect(status, equals(MemberStatusType.expired));
    });

    test('returns expired when subscriptionEndDate has passed', () {
      final status = resolveMemberStatus(
        isSuspended: false,
        subscriptionEndDate: fixedNow.subtract(const Duration(days: 1)),
        now: fixedNow,
      );
      expect(status, equals(MemberStatusType.expired));
    });

    test('returns expiringSoon when subscription ends within window (<= 7 days)', () {
      final status7Days = resolveMemberStatus(
        isSuspended: false,
        subscriptionEndDate: fixedNow.add(const Duration(days: 7)),
        daysBeforeExpiry: 7,
        now: fixedNow,
      );
      expect(status7Days, equals(MemberStatusType.expiringSoon));

      final statusToday = resolveMemberStatus(
        isSuspended: false,
        subscriptionEndDate: fixedNow,
        daysBeforeExpiry: 7,
        now: fixedNow,
      );
      expect(statusToday, equals(MemberStatusType.expiringSoon));
    });

    test('returns active when subscription ends in more than window (> 7 days)', () {
      final status = resolveMemberStatus(
        isSuspended: false,
        subscriptionEndDate: fixedNow.add(const Duration(days: 15)),
        daysBeforeExpiry: 7,
        now: fixedNow,
      );
      expect(status, equals(MemberStatusType.active));
    });
  });
}
