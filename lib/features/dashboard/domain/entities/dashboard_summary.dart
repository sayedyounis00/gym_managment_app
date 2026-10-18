import 'package:equatable/equatable.dart';
import 'expiring_subscription.dart';

class DashboardSummary extends Equatable {
  final int activeMembersCount;
  final int newSubscriptionsThisMonth;
  final List<ExpiringSubscription> expiringSoon;
  final double monthRevenue;
  final double monthExpenses;
  final double todayRevenue;

  const DashboardSummary({
    required this.activeMembersCount,
    required this.newSubscriptionsThisMonth,
    required this.expiringSoon,
    required this.monthRevenue,
    required this.monthExpenses,
    this.todayRevenue = 0.0,
  });

  double get netProfit => monthRevenue - monthExpenses;

  @override
  List<Object?> get props => [
        activeMembersCount,
        newSubscriptionsThisMonth,
        expiringSoon,
        monthRevenue,
        monthExpenses,
        todayRevenue,
      ];
}
