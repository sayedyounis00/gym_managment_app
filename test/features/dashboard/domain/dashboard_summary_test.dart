import 'package:flutter_test/flutter_test.dart';
import 'package:gym_managment_app/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:gym_managment_app/features/dashboard/domain/entities/expiring_subscription.dart';

void main() {
  group('DashboardSummary Entity', () {
    test('computes positive netProfit correctly (revenue > expenses)', () {
      final summary = DashboardSummary(
        activeMembersCount: 10,
        newSubscriptionsThisMonth: 3,
        expiringSoon: const [],
        monthRevenue: 1500.0,
        monthExpenses: 400.0,
        todayRevenue: 100.0,
      );

      expect(summary.netProfit, 1100.0);
    });

    test('computes negative netProfit correctly (revenue < expenses)', () {
      final summary = DashboardSummary(
        activeMembersCount: 2,
        newSubscriptionsThisMonth: 0,
        expiringSoon: const [],
        monthRevenue: 300.0,
        monthExpenses: 800.0,
        todayRevenue: 0.0,
      );

      expect(summary.netProfit, -500.0);
    });

    test('computes zero netProfit correctly', () {
      final summary = DashboardSummary(
        activeMembersCount: 5,
        newSubscriptionsThisMonth: 1,
        expiringSoon: const [],
        monthRevenue: 500.0,
        monthExpenses: 500.0,
      );

      expect(summary.netProfit, 0.0);
    });

    test('props equality works as expected', () {
      final date = DateTime(2026, 10, 17);
      final sub = ExpiringSubscription(
        memberId: 1,
        memberName: 'Alex',
        phone: '12345',
        endDate: date,
        daysLeft: 2,
      );

      final s1 = DashboardSummary(
        activeMembersCount: 5,
        newSubscriptionsThisMonth: 2,
        expiringSoon: [sub],
        monthRevenue: 500.0,
        monthExpenses: 200.0,
      );

      final s2 = DashboardSummary(
        activeMembersCount: 5,
        newSubscriptionsThisMonth: 2,
        expiringSoon: [sub],
        monthRevenue: 500.0,
        monthExpenses: 200.0,
      );

      expect(s1, equals(s2));
    });
  });
}
